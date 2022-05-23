resource "aws_cognito_user_pool" "dragons-pool" {
  name                     = "dragons-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
}

resource "aws_cognito_user_pool_client" "dragons-webclient" {
  name = "dragons-webclient"

  user_pool_id = aws_cognito_user_pool.dragons-pool.id

  callback_urls = [
    "https://${aws_s3_bucket.dragons-app-s3-bucket.bucket_domain_name}/dragonsapp/index.html"
  ]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_scopes                 = ["openid"]
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "dragons-pool-domain" {
  domain       = "obarcelonap-bmja-dragons-app"
  user_pool_id = aws_cognito_user_pool.dragons-pool.id
}
