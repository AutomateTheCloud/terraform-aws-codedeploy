output "metadata" {
  description = "Metadata"
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    codedeploy = {
      name     = aws_codedeploy_app.this.name
      iam_role = aws_iam_role.this.arn
      s3_bucket = (var.s3_bucket != "" ? {
        id   = data.aws_s3_bucket.this[0].id
        path = "codedeploy/${aws_codedeploy_app.this.name}"
      } : null)
      cloudwatch_log_group_names = var.cloudwatch_log_group_names
    }
  }
}