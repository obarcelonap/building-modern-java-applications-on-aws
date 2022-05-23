output "dragons-app-url" {
  value     = "https://${aws_s3_bucket.dragons-app-s3-bucket.bucket_domain_name}/dragonsapp/index.html"
  description = "The url where dragons app is hosted"
}

output "dragons-app-api-url" {
  value     = aws_api_gateway_deployment.dragons-app-api-deployment.invoke_url
  description = "The url where dragons app api can be invoked"
}
