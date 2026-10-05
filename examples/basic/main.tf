# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A CodeDeploy application for EC2 instances, and its service role, with only the
# required inputs.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "codedeploy" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Basic Application"
    environment = "Development"
  }

  name = "example-basic"
}

output "application_name" {
  description = "Name of the CodeDeploy application"
  value       = module.codedeploy.metadata.codedeploy_app.name
}

output "service_role_arn" {
  description = "ARN of the service role, for a deployment group's service_role_arn"
  value       = module.codedeploy.metadata.iam_role.arn
}
