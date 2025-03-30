data "aws_s3_bucket" "this" {
  count    = (var.s3_bucket != "" ? 1 : 0)
  bucket   = var.s3_bucket
  provider = aws.this
}
