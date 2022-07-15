locals {
  cors_params = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
  cors_values = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods"     = "'GET,OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"      = "'*'",
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

resource "aws_api_gateway_rest_api" "dragons-app-api-gateway" {
  name = "DragonsApp"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "dragons-app-api-gateway-resource" {
  parent_id   = aws_api_gateway_rest_api.dragons-app-api-gateway.root_resource_id
  path_part   = "dragons"
  rest_api_id = aws_api_gateway_rest_api.dragons-app-api-gateway.id
}

resource "aws_api_gateway_method" "dragons-app-api-gateway-method-get" {
  resource_id   = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  rest_api_id   = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.dragons-app-authorizer.id
}

resource "aws_api_gateway_integration" "dragons-app-api-integration-get" {
  rest_api_id             = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  resource_id             = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  http_method             = aws_api_gateway_method.dragons-app-api-gateway-method-get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.dragons_app_lambda_list_dragons.invoke_arn

  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }

  depends_on = [aws_lambda_function.dragons_app_lambda_list_dragons]
}

resource "aws_lambda_permission" "dragons-app-api-integration-get-permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dragons_app_lambda_list_dragons.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.dragons-app-api-gateway.id}/*/${aws_api_gateway_method.dragons-app-api-gateway-method-get.http_method}${aws_api_gateway_resource.dragons-app-api-gateway-resource.path}"
}

resource "aws_api_gateway_method_response" "dragons-app-api-integration-response-OK-get" {
  rest_api_id = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  resource_id = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  http_method = aws_api_gateway_method.dragons-app-api-gateway-method-get.http_method
  status_code = "200"

  response_parameters = local.cors_params
}

resource "aws_api_gateway_integration_response" "dragons-app-api-integration-response-get" {
  rest_api_id = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  resource_id = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  http_method = aws_api_gateway_method.dragons-app-api-gateway-method-get.http_method
  status_code = aws_api_gateway_method_response.dragons-app-api-integration-response-OK-get.status_code

  response_parameters = local.cors_values

  depends_on = [aws_api_gateway_integration.dragons-app-api-integration-get]
}

resource "aws_api_gateway_model" "dragons-app-api-model" {
  rest_api_id  = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  name         = "dragon"
  content_type = "application/json"

  schema = <<EOF
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Dragon",
  "type": "object",
  "properties": {
    "dragonName": { "type": "string" },
    "description": { "type": "string" },
    "family": { "type": "string" },
    "city": { "type": "string" },
    "country": { "type": "string" },
    "state": { "type": "string" },
    "neighborhood": { "type": "string" },
    "reportingPhoneNumber": { "type": "string" },
    "confirmationRequired": { "type": "boolean" }
  }
}
EOF
}

resource "aws_api_gateway_method" "dragons-app-api-gateway-method-post" {
  resource_id   = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  rest_api_id   = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.dragons-app-authorizer.id

  request_models = {
    "application/json" = aws_api_gateway_model.dragons-app-api-model.name
  }
  request_validator_id = aws_api_gateway_request_validator.dragons-app-api-request-validator.id
}

resource "aws_api_gateway_integration" "dragons-app-api-integration-post" {
  rest_api_id = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  resource_id = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  http_method = aws_api_gateway_method.dragons-app-api-gateway-method-post.http_method

  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:states:action/StartExecution"
  credentials             = aws_iam_role.dragons_app_api_gateway_role.arn
  integration_http_method = "POST"

  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates    = {
    "application/json" = <<EOF
#set($data = $input.path('$'))

#set($input = " {
  ""dragon_name_str"" : ""$data.dragonName"",
  ""description_str"" : ""$data.description"",
  ""family_str"" : ""$data.family"",
  ""location_city_str"" : ""$data.city"",
  ""location_country_str"" : ""$data.country"",
  ""location_state_str"" : ""$data.state"",
  ""location_neighborhood_str"" : ""$data.neighborhood"",
  ""reportingPhoneNumber"" : ""$data.reportingPhoneNumber"",
  ""confirmationRequired"" : $data.confirmationRequired}")

{
    "input": "$util.escapeJavaScript($input).replaceAll("\\'", "'")",
    "stateMachineArn": "${aws_sfn_state_machine.dragons_state_machine.arn}"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "dragons-app-api-integration-response-OK-post" {
  rest_api_id = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  resource_id = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  http_method = aws_api_gateway_method.dragons-app-api-gateway-method-post.http_method
  status_code = "200"

  response_parameters = local.cors_params

  depends_on = [aws_api_gateway_integration.dragons-app-api-integration-post]
}

resource "aws_api_gateway_integration_response" "dragons-app-api-integration-response-post" {
  rest_api_id = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  resource_id = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  http_method = aws_api_gateway_method.dragons-app-api-gateway-method-post.http_method
  status_code = aws_api_gateway_method_response.dragons-app-api-integration-response-OK-post.status_code

  response_parameters = local.cors_values
}

resource "aws_api_gateway_request_validator" "dragons-app-api-request-validator" {
  name                  = "DragonsRequestValidator"
  rest_api_id           = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  validate_request_body = true
}

resource "aws_api_gateway_deployment" "dragons-app-api-deployment" {
  depends_on = [
    aws_api_gateway_method.dragons-app-api-gateway-method-get,
    aws_api_gateway_method.dragons-app-api-gateway-method-post
  ]
  rest_api_id = aws_api_gateway_rest_api.dragons-app-api-gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.dragons-app-api-gateway-method-get.id,
      aws_api_gateway_method_response.dragons-app-api-integration-response-OK-get.id,
      aws_api_gateway_integration.dragons-app-api-integration-get.id,
      aws_api_gateway_integration_response.dragons-app-api-integration-response-get.id,
      aws_api_gateway_method.dragons-app-api-gateway-method-post.id,
      aws_api_gateway_method_response.dragons-app-api-integration-response-OK-post.id,
      aws_api_gateway_integration.dragons-app-api-integration-post.id,
      aws_api_gateway_integration_response.dragons-app-api-integration-response-post.id,
      aws_api_gateway_model.dragons-app-api-model.id,
      aws_api_gateway_request_validator.dragons-app-api-request-validator.id,
      aws_api_gateway_rest_api.dragons-app-api-gateway.body
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dragons-app-api-stage" {
  deployment_id = aws_api_gateway_deployment.dragons-app-api-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  stage_name    = "prod"

  xray_tracing_enabled  = true
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"
}

module "api-gateway-enable-cors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id            = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  api_resource_id   = aws_api_gateway_resource.dragons-app-api-gateway-resource.id
  allow_credentials = true
}

resource "aws_api_gateway_authorizer" "dragons-app-authorizer" {
  name            = "dragons-app-authorizer"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.dragons-app-api-gateway.id
  provider_arns   = [aws_cognito_user_pool.dragons-pool.arn]
  identity_source = "method.request.header.authorization"
}
