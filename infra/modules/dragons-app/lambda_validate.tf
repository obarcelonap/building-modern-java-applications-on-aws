locals {
  validate_lambda_base_path = "${path.module}/../../../java-dragons-lambda/validateDragon"
  validate_lambda_src_hash  = base64sha256(join("", [
    file("${local.validate_lambda_base_path}/src/main/java/com/mycompany/app/ValidateDragon.java"),
    file("${local.validate_lambda_base_path}/src/main/java/com/mycompany/app/DragonValidationException.java"),
    file("${local.validate_lambda_base_path}/build.gradle")
  ]))
  validate_lambda_archive = "${local.validate_lambda_base_path}/build/distributions/validateDragon.zip"
}

resource "null_resource" "dragons_app_lambda_validate_dragon_build" {
  triggers = {
    source_code_hash = local.validate_lambda_src_hash
  }

  provisioner "local-exec" {
    command     = "./gradlew build"
    working_dir = local.validate_lambda_base_path
  }
}

resource "aws_lambda_function" "dragons_app_lambda_validate_dragon" {
  function_name    = "dragons-app-lambda-validate-dragon"
  handler          = "com.mycompany.app.ValidateDragon::handleRequest"
  role             = aws_iam_role.dragons_app_read_lambda_role.arn
  runtime          = "java11"
  source_code_hash = local.validate_lambda_archive
  timeout          = 90
  memory_size      = 448
  filename         = local.validate_lambda_archive
  depends_on       = [null_resource.dragons_app_lambda_validate_dragon_build]
}
