# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # The AWS managed policy CodeDeploy documents for each compute platform. The ARN is
  # built from the partition, so it also works in AWS GovCloud (US) and China.
  iam_policy_name = {
    Server = "service-role/AWSCodeDeployRole"
    ECS    = "AWSCodeDeployRoleForECS"
    Lambda = "service-role/AWSCodeDeployRoleForLambda"
  }
  iam_policy_arn = "arn:${data.aws_partition.this.partition}:iam::aws:policy/${local.iam_policy_name[var.compute_platform]}"

  # One service role per scope, purpose, environment and Region.
  iam_role_name = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}-codedeploy"

  # The revision bucket is not read, so that it can be created in the same run.
  s3_bucket = var.s3_bucket == null ? null : {
    arn    = "arn:${data.aws_partition.this.partition}:s3:::${var.s3_bucket.name}"
    bucket = var.s3_bucket.name
    path   = coalesce(var.s3_bucket.path, "codedeploy/${var.name}")
  }
}
