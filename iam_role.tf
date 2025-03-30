resource "aws_iam_role" "this" {
  name               = "${local.scope.abbr}-${local.purpose.abbr}-${local.environment.abbr}-${local.aws.region.abbr}-codedeploy"
  description        = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): CodeDeploy"
  assume_role_policy = data.aws_iam_policy_document.iam_role-this-assume_role_policy.json
  tags               = local.tags
  provider           = aws.this
}

data "aws_iam_policy_document" "iam_role-this-assume_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "codedeploy.amazonaws.com"
      ]
    }
  }
  provider = aws.this
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.id
  policy_arn = local.iam_policy_lookup[var.compute_platform]
  provider   = aws.this
}
