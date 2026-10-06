# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_codedeploy_app" "this" {
  region           = var.region
  name             = var.name
  compute_platform = var.compute_platform
  tags             = merge(local.tags, { "Name" = var.name })
}
