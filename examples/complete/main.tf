# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A CodeDeploy application for EC2 instances that uses most of the module's inputs: a
# revision bucket and log groups created in the same configuration, and a deployment
# group that uses the module's service role. Each input is explained in the module
# README.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  details = {
    scope       = "Example"
    purpose     = "Complete Application"
    environment = "Production"
    additional_tags = {
      Project = "Example Project"
    }
  }
}

# Bucket names are global, so this one ends in a random suffix.
resource "random_id" "suffix" {
  byte_length = 4
}

# A private, encrypted bucket for the application's revisions. CodeDeploy needs it in
# the application's Region. Versioning keeps every revision that is overwritten, so a
# deployment can name an exact version; old versions are deleted after 30 days.
module "artifacts" {
  source  = "AutomateTheCloud/s3_bucket/aws"
  version = "~> 1.0"

  details    = local.details
  name       = "example-codedeploy-${random_id.suffix.hex}"
  versioning = { enabled = true }

  lifecycle_rules = [
    {
      rule_name                              = "Clean up old versions"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      noncurrent_version_expiration          = { days = 30 }
      expiration                             = { expired_object_delete_marker = true }
    }
  ]
}

# Log groups for the application's own logs, which the CloudWatch agent on the
# instances writes to.
resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(["access", "error"])

  name              = "/example-complete/${each.key}"
  retention_in_days = 30
  tags              = module.codedeploy.metadata.details.tags
}

module "codedeploy" {
  source = "../../"

  details = local.details

  name             = "example-complete"
  compute_platform = "Server"

  # Optional: create the application in another Region than the provider's. The
  # revision bucket must then be in that Region too.
  # region = "us-west-2"

  # The bucket is created in this run, so its name is not known until apply.
  s3_bucket = {
    name = module.artifacts.metadata.s3_bucket.id
    path = "releases/example-complete"
  }

  cloudwatch_log_group_names = ["/example-complete/access", "/example-complete/error"]
}

# Deploys to every EC2 instance tagged CodeDeployGroup = example-complete-web, one at a
# time, and rolls back if a deployment fails. With no such instances, deployments have
# nothing to do, so the example is safe to apply.
resource "aws_codedeploy_deployment_group" "web" {
  app_name               = module.codedeploy.metadata.codedeploy_app.name
  deployment_group_name  = "web"
  service_role_arn       = module.codedeploy.metadata.iam_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "CodeDeployGroup"
      type  = "KEY_AND_VALUE"
      value = "example-complete-web"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  tags = module.codedeploy.metadata.details.tags
}

output "application_name" {
  description = "Name of the CodeDeploy application"
  value       = module.codedeploy.metadata.codedeploy_app.name
}

output "revision_location" {
  description = "Where to upload revisions: s3://<bucket>/<path>/"
  value       = "s3://${module.codedeploy.metadata.s3_bucket.bucket}/${module.codedeploy.metadata.s3_bucket.path}/"
}
