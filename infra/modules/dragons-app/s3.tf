locals {
  dragons_app_path = "${path.module}/webapp2"
  dragons_app_data = "${path.module}/dragon_stats_one.txt"
  content_type_map = {
    html = "text/html",
    js   = "application/javascript",
    css  = "text/css",
    svg  = "image/svg+xml",
    jpg  = "image/jpeg",
    ico  = "image/x-icon",
    png  = "image/png",
    gif  = "image/gif",
    txt  = "text/plain",
  }
}

resource "aws_s3_bucket" "dragons-app-s3-bucket" {
  bucket = "obarcelonap-bmjaoaws-dragons-app"
}

resource "aws_s3_bucket_acl" "dragons-app-s3-bucket-acl" {
  bucket = aws_s3_bucket.dragons-app-s3-bucket.bucket
  acl    = "public-read"
}

resource "aws_s3_object" "upload-dragons-app-to-s3-bucket" {
  for_each = fileset(local.dragons_app_path, "**/*")

  bucket = aws_s3_bucket.dragons-app-s3-bucket.bucket
  acl    = "public-read"
  key    = "dragonsapp/${each.value}"
  source = "${local.dragons_app_path}/${each.value}"
  etag   = filemd5("${local.dragons_app_path}/${each.value}")

  content_type = lookup(local.content_type_map, regex("\\.(?P<extension>[A-Za-z0-9]+)$", each.value).extension, "application/octet-stream")
}

resource "aws_s3_object" "upload-dragons-data-to-s3-bucket" {
  bucket = aws_s3_bucket.dragons-app-s3-bucket.bucket
  acl    = "public-read"
  key    = "dragon_stats_one.txt"
  source = local.dragons_app_data
  etag   = filemd5(local.dragons_app_data)

  content_type = "text/plain"
}
