# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_service_principal" {
    defaults = { name = "codedeploy.amazonaws.com" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111111111111:role/test-role" }
  }
}

variables {
  details = { scope = "Test", purpose = "Defaults", environment = "test" }
  name    = "my-app"
}

# Only the required inputs.
run "defaults" {
  command = plan

  assert {
    condition     = aws_codedeploy_app.this.name == "my-app" && aws_codedeploy_app.this.compute_platform == "Server"
    error_message = "The application should be named my-app, on the Server platform."
  }
  assert {
    condition     = aws_iam_role_policy_attachment.this.policy_arn == "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
    error_message = "The Server platform should attach AWSCodeDeployRole."
  }
  assert {
    condition = alltrue([
      for s in data.aws_iam_policy_document.iam_role_assume_role_policy.statement : (
        s.effect == "Allow" && s.actions == toset(["sts:AssumeRole"]) &&
        alltrue([for p in s.principals : p.type == "Service" && p.identifiers == toset(["codedeploy.amazonaws.com"])])
      )
    ])
    error_message = "Only the CodeDeploy service may assume the role."
  }
  assert {
    condition     = output.metadata.s3_bucket == null
    error_message = "No bucket is read without s3_bucket."
  }
  assert {
    condition     = length(output.metadata.cloudwatch_log_group_names) == 0
    error_message = "No log groups by default."
  }
}

# Regression: compute_platform defaulted to "", which failed to plan with an invalid index.
run "compute_platform_default_is_server" {
  command = plan
  assert {
    condition     = var.compute_platform == "Server"
    error_message = "compute_platform should default to Server."
  }
}

# Regression: the application was not tagged.
run "every_resource_tagged" {
  command = plan
  variables {
    details = { scope = "Test", purpose = "Defaults", environment = "test", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition = aws_codedeploy_app.this.tags == tomap({
      Scope = "Test", Purpose = "Defaults", Environment = "test", CostCenter = "1234", Name = "my-app"
    })
    error_message = "Unexpected application tags."
  }
  assert {
    condition = aws_iam_role.this.tags == tomap({
      Scope = "Test", Purpose = "Defaults", Environment = "test", CostCenter = "1234", Name = "test-defaults-test-use1-codedeploy"
    })
    error_message = "Unexpected role tags."
  }
}

# The role name comes from details and the Region.
run "role_name" {
  command = plan
  assert {
    condition     = aws_iam_role.this.name == "test-defaults-test-use1-codedeploy"
    error_message = "Role name is ${aws_iam_role.this.name}."
  }
}

# Regression: an empty abbreviation override produced an empty abbreviation.
run "empty_abbr_ignored" {
  command = plan
  variables {
    details = { scope = "Test", scope_abbr = "", purpose = "Defaults", environment = "test" }
  }
  assert {
    condition     = output.metadata.details.scope.abbr == "test" && aws_iam_role.this.name == "test-defaults-test-use1-codedeploy"
    error_message = "An empty scope_abbr should fall back to the generated abbreviation."
  }
}

run "platform_ecs" {
  command = plan
  variables { compute_platform = "ECS" }
  assert {
    condition     = aws_codedeploy_app.this.compute_platform == "ECS" && aws_iam_role_policy_attachment.this.policy_arn == "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
    error_message = "The ECS platform should attach AWSCodeDeployRoleForECS."
  }
}

run "platform_lambda" {
  command = plan
  variables { compute_platform = "Lambda" }
  assert {
    condition     = aws_codedeploy_app.this.compute_platform == "Lambda" && aws_iam_role_policy_attachment.this.policy_arn == "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
    error_message = "The Lambda platform should attach AWSCodeDeployRoleForLambda."
  }
}

# Regression: the policy ARN was hard-coded to the aws partition.
run "partition_govcloud" {
  command = plan
  override_data {
    target = data.aws_partition.this
    values = { partition = "aws-us-gov" }
  }
  assert {
    condition     = aws_iam_role_policy_attachment.this.policy_arn == "arn:aws-us-gov:iam::aws:policy/service-role/AWSCodeDeployRole"
    error_message = "policy_arn is ${aws_iam_role_policy_attachment.this.policy_arn}."
  }
}

run "log_group_names" {
  command = plan
  variables { cloudwatch_log_group_names = ["/my-app/access", "/my-app/error"] }
  assert {
    condition     = output.metadata.cloudwatch_log_group_names == tolist(["/my-app/access", "/my-app/error"])
    error_message = "Log group names should pass through to metadata."
  }
}

run "defaults_apply" {
  command = apply
  assert {
    condition     = output.metadata.iam_role.arn == "arn:aws:iam::111111111111:role/test-role"
    error_message = "metadata.iam_role.arn is wrong."
  }
  assert {
    condition     = output.metadata.codedeploy_app.name == "my-app"
    error_message = "metadata.codedeploy_app.name is wrong."
  }
  assert {
    condition     = output.metadata.aws.account.id == "111111111111" && output.metadata.aws.region.abbr == "use1"
    error_message = "metadata.aws is wrong."
  }
  assert {
    condition     = output.metadata.details.purpose.abbr == "defaults" && output.metadata.details.purpose.machine == "defaults"
    error_message = "metadata.details is wrong."
  }
}
