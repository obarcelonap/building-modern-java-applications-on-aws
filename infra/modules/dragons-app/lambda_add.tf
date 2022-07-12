locals {
  add_lambda_base_path = "${path.module}/../../../java-dragons-lambda/addDragon"
  add_lambda_src_hash  = base64sha256(join("", [
    file("${local.add_lambda_base_path}/src/main/java/com/mycompany/app/AddDragon.java"),
    file("${local.add_lambda_base_path}/src/main/java/com/mycompany/app/model/Dragon.java"),
    file("${local.add_lambda_base_path}/build.gradle")
  ]))
  add_lambda_archive = "${local.add_lambda_base_path}/build/distributions/addDragon.zip"
}

resource "null_resource" "dragons_app_lambda_add_dragon_build" {
  triggers = {
    source_code_hash = local.add_lambda_src_hash
  }

  provisioner "local-exec" {
    command     = "./gradlew build"
    working_dir = local.add_lambda_base_path
  }
}

resource "aws_lambda_function" "dragons_app_lambda_add_dragon" {
  function_name    = "dragons-app-lambda-add-dragon"
  handler          = "com.mycompany.app.AddDragon::handleRequest"
  role             = aws_iam_role.dragons_app_read_write_lambda_role.arn
  runtime          = "java11"
  source_code_hash = local.add_lambda_src_hash
  timeout          = 90
  memory_size      = 448
  filename         = local.add_lambda_archive
  depends_on       = [null_resource.dragons_app_lambda_add_dragon_build]

}
