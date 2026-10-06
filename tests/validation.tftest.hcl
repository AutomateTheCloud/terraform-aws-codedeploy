# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

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
  details = { scope = "Test", purpose = "Validation", environment = "test" }
  name    = "my-app"
}

run "scope_required" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "purpose_required" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "environment_required" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

# Regression: an empty name used to plan, and failed only in the provider.
run "name_empty" {
  command = plan
  variables { name = "" }
  expect_failures = [var.name]
}

run "name_too_long" {
  command = plan
  variables { name = "a12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901" }
  expect_failures = [var.name]
}

run "compute_platform_invalid" {
  command = plan
  variables { compute_platform = "EC2" }
  expect_failures = [var.compute_platform]
}

# Regression: a role name over IAM's 64 characters failed in the provider with no hint.
run "role_name_too_long" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud Education", purpose = "Student Web Applications", environment = "Production" }
  }
  expect_failures = [aws_iam_role.this]
}

run "s3_bucket_name_invalid" {
  command = plan
  variables { s3_bucket = { name = "My_Bucket" } }
  expect_failures = [var.s3_bucket]
}

run "s3_bucket_path_leading_slash" {
  command = plan
  variables { s3_bucket = { name = "my-artifacts-use1", path = "/releases" } }
  expect_failures = [var.s3_bucket]
}

run "log_group_name_invalid" {
  command = plan
  variables { cloudwatch_log_group_names = ["has space"] }
  expect_failures = [var.cloudwatch_log_group_names]
}
