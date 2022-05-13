resource "aws_ssm_parameter" "dragon-data-bucket-name" {
  name  = "dragon_data_bucket_name"
  type  = "String"
  value = aws_s3_object.upload-dragons-data-to-s3-bucket.bucket
}

resource "aws_ssm_parameter" "dragon-data-file-name" {
  name  = "dragon_data_file_name"
  type  = "String"
  value = aws_s3_object.upload-dragons-data-to-s3-bucket.key
}