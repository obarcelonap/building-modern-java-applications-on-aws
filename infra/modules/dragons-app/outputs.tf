output "dragons-app-url" {
  value     = "https://${aws_s3_bucket.dragons-app-s3-bucket.bucket_domain_name}/dragonsapp/index.html"
  description = "The url where dragons app is hosted"
}
