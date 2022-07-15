locals {
  list_lambda_base_path = "${path.module}/../../../java-dragons-lambda/listDragons"
  list_lambda_src_hash  = base64sha256(join("", [
    file("${local.list_lambda_base_path}/src/main/java/com/mycompany/app/ListDragons.java"),
    file("${local.list_lambda_base_path}/build.gradle")
  ]))
  list_lambda_archive = "${local.list_lambda_base_path}/build/distributions/listDragons.zip"
}

resource "null_resource" "dragons_app_lambda_list_dragons_build" {
  triggers = {
    source_code_hash = local.add_lambda_src_hash
  }

  provisioner "local-exec" {
    command     = "./gradlew build"
    working_dir = local.list_lambda_base_path
  }
}

resource "aws_lambda_function" "dragons_app_lambda_list_dragons" {
  function_name    = "dragons-app-lambda-list-dragons"
  handler          = "com.mycompany.app.ListDragons::handleRequest"
  role             = aws_iam_role.dragons_app_read_lambda_role.arn
  runtime          = "java11"
  source_code_hash = local.list_lambda_src_hash
  timeout          = 90
  memory_size      = 448
  filename         = local.list_lambda_archive
  depends_on       = [null_resource.dragons_app_lambda_list_dragons_build]

  tracing_config {
    mode = "Active"
  }
}
