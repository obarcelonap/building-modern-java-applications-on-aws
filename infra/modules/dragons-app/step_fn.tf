resource "aws_sfn_state_machine" "dragons_state_machine" {
  name     = "DragonsStateMachine"
  role_arn = aws_iam_role.dragons_state_machine_role.arn
  type     = "STANDARD"

  tracing_configuration {
    enabled = true
  }

  logging_configuration {
    level                  = "ALL"
    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.dragons_state_machine_role_log_group.arn}:*"
  }

  definition = <<EOF
{
  "Comment": "Dragon will be validated. If validation fails, a failure message will be sent. If the dragon is valid, it will be added to the data and a success message will be sent.",
  "StartAt": "ValidateDragon",
  "States": {
    "ValidateDragon": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.dragons_app_lambda_validate_dragon.arn}",
      "Catch": [
        {
          "ErrorEquals": [
            "DragonValidationException"
          ],
          "Next": "AlertDragonValidationFailure",
          "ResultPath": null
        },
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "CatchAllFailure"
        }
      ],
      "Next": "AddDragon",
      "ResultPath": null
    },
    "AlertDragonValidationFailure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "The dragon you reported failed validation and was not added.",
        "PhoneNumber.$": "$.reportingPhoneNumber"
      },
      "End": true
    },
    "CatchAllFailure": {
      "Type": "Fail",
      "Cause": "Something unknown went wrong."
    },
    "AddDragon": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.dragons_app_lambda_add_dragon.arn}",
      "Next": "ConfirmationRequired",
      "ResultPath": null
    },
    "ConfirmationRequired": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.confirmationRequired",
          "BooleanEquals": true,
          "Next": "AlertAddDragonSuccess"
        },
        {
          "Variable": "$.confirmationRequired",
          "BooleanEquals": false,
          "Next": "NoAlertAddDragonSuccess"
        }
      ],
      "Default": "CatchAllFailure"
    },
    "AlertAddDragonSuccess": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "The dragon you reported has been added!",
        "PhoneNumber.$": "$.reportingPhoneNumber"
      },
      "End": true
    },
    "NoAlertAddDragonSuccess": {
      "Type": "Succeed"
    }
  }
}
EOF
}

resource "aws_cloudwatch_log_group" "dragons_state_machine_role_log_group" {
  name = "dragons_state_machine_role_log_group"
}

resource "aws_iam_role" "dragons_state_machine_role" {
  name               = "dragons-state-machine-role"
  assume_role_policy = data.aws_iam_policy_document.dragons_app_state_machine_assume_policy_doc.json
}

resource "aws_iam_role_policy" "dragons_state_machine_role_policy" {
  policy = data.aws_iam_policy_document.dragons_app_state_machine_role_policy_doc.json
  role   = aws_iam_role.dragons_state_machine_role.id
}

resource "aws_iam_role_policy_attachment" "dragons_state_machine_role_policy_xray" {
  role       = aws_iam_role.dragons_state_machine_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

data "aws_iam_policy_document" "dragons_app_state_machine_assume_policy_doc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dragons_app_state_machine_role_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.dragons_app_lambda_validate_dragon.arn,
      aws_lambda_function.dragons_app_lambda_add_dragon.arn,
    ]
  }
  statement {
    effect  = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutLogEvents",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }
}
