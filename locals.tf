locals {
  name = "test"

  iam_policy_lookup = {
    Server = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
    ECS    = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
    Lambda = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
  }
}
