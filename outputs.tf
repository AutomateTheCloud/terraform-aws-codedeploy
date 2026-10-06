# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the application.
    - `codedeploy_app` - The application, including its `name`, `arn`, `application_id` and `compute_platform`. Deployment groups and deployment configurations take its `name`.
    - `iam_role` - The service role, including its `name` and `arn`. Give the `arn` to each deployment group as its `service_role_arn`.
    - `iam_role_policy_attachment` - The AWS managed policy attached to the service role: its `policy_arn` and `role`.
    - `s3_bucket` - The revision bucket's `bucket` (name) and `arn`, and `path`, the key prefix for this application's revisions. `null` unless `s3_bucket` is set.
    - `cloudwatch_log_group_names` - The log group names from the input of the same name.
  EOT
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

    # One entry per resource. Resources that are not created are null.
    codedeploy_app             = local.output_resources.codedeploy_app
    iam_role                   = local.output_resources.iam_role
    iam_role_policy_attachment = local.output_resources.iam_role_policy_attachment
    s3_bucket                  = local.output_resources.s3_bucket
    cloudwatch_log_group_names = var.cloudwatch_log_group_names
  }
}

# Each resource's attributes, listed one by one: referencing a whole resource would
# also reference its deprecated and sensitive attributes, and every caller's plan
# would then print warnings or the output would become sensitive.
locals {
  output_resources = {
    codedeploy_app = {
      application_id      = aws_codedeploy_app.this.application_id
      arn                 = aws_codedeploy_app.this.arn
      compute_platform    = aws_codedeploy_app.this.compute_platform
      github_account_name = aws_codedeploy_app.this.github_account_name
      id                  = aws_codedeploy_app.this.id
      linked_to_github    = aws_codedeploy_app.this.linked_to_github
      name                = aws_codedeploy_app.this.name
      region              = aws_codedeploy_app.this.region
      tags                = aws_codedeploy_app.this.tags
      tags_all            = aws_codedeploy_app.this.tags_all
    }

    iam_role = {
      arn                   = aws_iam_role.this.arn
      assume_role_policy    = aws_iam_role.this.assume_role_policy
      create_date           = aws_iam_role.this.create_date
      description           = aws_iam_role.this.description
      force_detach_policies = aws_iam_role.this.force_detach_policies
      id                    = aws_iam_role.this.id
      max_session_duration  = aws_iam_role.this.max_session_duration
      name                  = aws_iam_role.this.name
      name_prefix           = aws_iam_role.this.name_prefix
      path                  = aws_iam_role.this.path
      permissions_boundary  = aws_iam_role.this.permissions_boundary
      tags                  = aws_iam_role.this.tags
      tags_all              = aws_iam_role.this.tags_all
      unique_id             = aws_iam_role.this.unique_id
    }

    iam_role_policy_attachment = {
      id         = aws_iam_role_policy_attachment.this.id
      policy_arn = aws_iam_role_policy_attachment.this.policy_arn
      role       = aws_iam_role_policy_attachment.this.role
    }

    # The revision bucket, from the s3_bucket input.
    s3_bucket = local.s3_bucket
  }
}
