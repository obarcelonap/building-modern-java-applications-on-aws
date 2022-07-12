resource "aws_iam_role" "dragons_app_api_gateway_role" {
  name               = "dragons-app-api-gateway-role"
  assume_role_policy = data.aws_iam_policy_document.dragons_app_api_gateway_assume_policy_doc.json
}

resource "aws_iam_role_policy" "dragons_app_api_gateway_role_policy" {
  policy = data.aws_iam_policy_document.dragons_app_api_gateway_role_policy_doc.json
  role   = aws_iam_role.dragons_app_api_gateway_role.id
}

resource "aws_iam_role_policy_attachment" "dragons_state_machine_role_policy_logging" {
  role       = aws_iam_role.dragons_app_api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

data "aws_iam_policy_document" "dragons_app_api_gateway_assume_policy_doc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dragons_app_api_gateway_role_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = ["*"]
  }
}
