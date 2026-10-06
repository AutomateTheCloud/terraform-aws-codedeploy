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
mock_provider "random" {}

variables {
  details = { scope = "Test", purpose = "Bucket", environment = "test" }
  name    = "my-app"
}

run "bucket_in_metadata" {
  command   = apply
  providers = { aws = aws }
  variables { s3_bucket = { name = "my-artifacts-use1" } }
  assert {
    condition     = output.metadata.s3_bucket.arn == "arn:aws:s3:::my-artifacts-use1" && output.metadata.s3_bucket.bucket == "my-artifacts-use1"
    error_message = "metadata.s3_bucket is wrong."
  }
  assert {
    condition     = output.metadata.s3_bucket.path == "codedeploy/my-app"
    error_message = "The default path should be codedeploy/<name>."
  }
}

run "bucket_path" {
  command   = apply
  providers = { aws = aws }
  variables { s3_bucket = { name = "my-artifacts-use1", path = "releases/my-app" } }
  assert {
    condition     = output.metadata.s3_bucket.path == "releases/my-app"
    error_message = "s3_bucket.path was not used."
  }
}

# Regression: s3_bucket from a bucket created in the same run failed to plan, because
# the count depended on a value not known until apply.
run "bucket_created_in_same_run" {
  command   = plan
  providers = { aws = aws, random = random }
  module {
    source = "./tests/fixtures/same_run_bucket"
  }
  assert {
    condition     = module.codedeploy.metadata.s3_bucket != null
    error_message = "The bucket was not planned."
  }
}
