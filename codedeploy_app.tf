resource "aws_codedeploy_app" "this" {
  name             = var.name
  compute_platform = var.compute_platform
  provider         = aws.this
}
