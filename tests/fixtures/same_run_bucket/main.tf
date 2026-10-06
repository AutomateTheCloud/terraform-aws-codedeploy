# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An application whose revision bucket name is not known until apply, as when the
# bucket is created in the same run. A random suffix stands in for the bucket, so the
# fixture creates no unprotected bucket that a security scan would flag.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

resource "random_id" "this" {
  byte_length = 4
}

module "codedeploy" {
  source = "../../.."

  details   = { scope = "Test", purpose = "Bucket", environment = "test" }
  name      = "my-app"
  s3_bucket = { name = "artifacts-${random_id.this.hex}" }
}
