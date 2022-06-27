output "dragons-app-url" {
  value       = "https://${aws_s3_bucket.dragons-app-s3-bucket.bucket_domain_name}/dragonsapp/index.html"
  description = "The url where dragons app is hosted"
}

output "dragons-app-api-url" {
  value       = aws_api_gateway_deployment.dragons-app-api-deployment.invoke_url
  description = "The url where dragons app api can be invoked"
}

output "dragons-app-webclient-id" {
  value       = aws_cognito_user_pool_client.dragons-webclient.id
  description = "The client id to authenticate to dragons app"
}

output "dragons-app-login-url" {
  value       = "${aws_cognito_user_pool_domain.dragons-pool-domain.domain}.auth.us-east-1.amazoncognito.com"
  description = "The url where dragons app is authenticating users"
}

output "dragons-app-list-dragons-lambda-arns" {
  value = {
    add      = aws_lambda_function.dragons_app_lambda_add_dragon.arn
    list     = aws_lambda_function.dragons_app_lambda_list_dragons.arn
    validate = aws_lambda_function.dragons_app_lambda_validate_dragon.arn
  }
  description = "The arns of the lambda functions"
}
