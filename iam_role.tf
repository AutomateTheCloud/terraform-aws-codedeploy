# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The service role CodeDeploy assumes to deploy the application. A deployment group
# names it in its service_role_arn.
resource "aws_iam_role" "this" {
  name               = local.iam_role_name
  description        = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): CodeDeploy"
  assume_role_policy = data.aws_iam_policy_document.iam_role_assume_role_policy.json
  tags               = merge(local.tags, { "Name" = local.iam_role_name })

  lifecycle {
    precondition {
      condition     = length(local.iam_role_name) <= 64
      error_message = "The IAM role name ${local.iam_role_name} is ${length(local.iam_role_name)} characters; IAM allows 64. Set shorter details.scope_abbr, purpose_abbr or environment_abbr."
    }
  }
}

data "aws_iam_policy_document" "iam_role_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [data.aws_service_principal.codedeploy.name]
    }
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = local.iam_policy_arn
}
