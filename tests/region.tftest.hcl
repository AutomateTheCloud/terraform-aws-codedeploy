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
  details   = { scope = "Test", purpose = "Region", environment = "test" }
  name      = "my-app"
  s3_bucket = { name = "my-artifacts" }
}

# The module needs no providers block: it uses the default aws provider.
run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables { region = "eu-west-1" }
  assert {
    condition = alltrue([
      aws_codedeploy_app.this.region == "eu-west-1",
      data.aws_region.this.region == "eu-west-1",
      data.aws_service_principal.codedeploy.region == "eu-west-1",
      output.metadata.aws.region.name == "eu-west-1",
      aws_iam_role.this.name == "test-region-test-euw1-codedeploy",
    ])
    error_message = "region was not passed through to every resource and data source."
  }
}

# Regression: Regions missing from the old hard-coded table failed to plan.
run "region_not_in_old_table" {
  command = plan
  variables {
    region    = "mx-central-1"
    s3_bucket = null
  }
  assert {
    condition     = output.metadata.aws.region.abbr == "mxc1" && aws_iam_role.this.name == "test-region-test-mxc1-codedeploy"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_new_region" {
  command = plan
  variables {
    region    = "ap-southeast-7"
    s3_bucket = null
  }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables {
    region    = "us-gov-west-1"
    s3_bucket = null
  }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}
