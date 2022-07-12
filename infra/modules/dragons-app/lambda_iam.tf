resource "aws_iam_role" "dragons_app_read_lambda_role" {
  name               = "dragons-read-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.dragons_app_lambda_assume_policy_doc.json
}

resource "aws_iam_role_policy" "dragons_app_read_policy" {
  policy = data.aws_iam_policy_document.dragons_app_read_policy_doc.json
  role   = aws_iam_role.dragons_app_read_lambda_role.id
}

resource "aws_iam_role_policy_attachment" "dragons_app_read_lambda_role_policy_xray" {
  role       = aws_iam_role.dragons_app_read_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role" "dragons_app_read_write_lambda_role" {
  name               = "dragons-read-write-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.dragons_app_lambda_assume_policy_doc.json
}

resource "aws_iam_role_policy" "dragons_app_read_write_policy" {
  policy = data.aws_iam_policy_document.dragons_app_read_write_policy_doc.json
  role   = aws_iam_role.dragons_app_read_write_lambda_role.id
}

resource "aws_iam_role_policy_attachment" "dragons_app_read_write_lambda_role_policy_xray" {
  role       = aws_iam_role.dragons_app_read_write_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

data "aws_iam_policy_document" "dragons_app_lambda_assume_policy_doc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dragons_app_read_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [aws_s3_bucket.dragons-app-s3-bucket.arn]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.dragon-data-bucket-name.arn,
      aws_ssm_parameter.dragon-data-file-name.arn,
    ]
  }
}

data "aws_iam_policy_document" "dragons_app_read_write_policy_doc" {
  statement {
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.dragons-app-s3-bucket.arn}/*"]
  }
  statement {
    effect  = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.dragon-data-bucket-name.arn,
      aws_ssm_parameter.dragon-data-file-name.arn,
    ]
  }
}