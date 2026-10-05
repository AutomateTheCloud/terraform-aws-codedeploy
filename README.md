# Terraform module for AWS CodeDeploy applications

Creates an AWS CodeDeploy application and the IAM service role that its deployment groups use. The application can deploy to EC2 instances and on-premises servers, Amazon Elastic Container Service (ECS) services, or AWS Lambda functions.

The service role can be assumed only by CodeDeploy, and has only the AWS managed policy that CodeDeploy documents for the application's compute platform. The module can also record in its output the S3 bucket that holds the application's revisions and the log groups the application writes to, so that other configurations can find them in one place.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Compute platform | EC2 and on-premises servers (`Server`) | `compute_platform` |
| Service role name | `<scope>-<purpose>-<environment>-<Region>-codedeploy`, from the abbreviations | `details` |
| Service role permissions | The AWS managed policy for the compute platform | Chosen by `compute_platform` |
| Revision bucket | None | `s3_bucket` |
| Log group names | None | `cloudwatch_log_group_names` |
| Region | The provider's | `region` |

The module does not create deployment groups, the revision bucket, or log groups: those depend on how you deploy. The [complete example](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/tree/main/examples/complete) creates all three around the module.

## Usage

```hcl
module "codedeploy" {
  source  = "AutomateTheCloud/codedeploy/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Web Site"
    environment = "Production"
  }

  name = "example-web-site"
}

resource "aws_codedeploy_deployment_group" "web" {
  app_name              = module.codedeploy.metadata.codedeploy_app.name
  deployment_group_name = "web"
  service_role_arn      = module.codedeploy.metadata.iam_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "CodeDeployGroup"
      type  = "KEY_AND_VALUE"
      value = "web"
    }
  }
}
```

`details` and `name` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on the application and the role.

The module uses the default `aws` provider, so it needs no `providers` block. The application is created in the provider's Region. To create it somewhere else without configuring another provider, set `region`:

```hcl
module "codedeploy_west" {
  source  = "AutomateTheCloud/codedeploy/aws"
  version = "~> 1.0"

  region           = "us-west-2"
  details          = { scope = "Automate the Cloud", purpose = "Web Site", environment = "Production" }
  name             = "example-web-site"
  compute_platform = "ECS"
}
```

IAM is global, so the service role is the same wherever the application is. Its name includes the Region's short form, such as `usw2`, so the same application in two Regions gets two roles.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the application belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at an application or role in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the application, its revision bucket, its instances and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "site_deploy" {
  source  = "AutomateTheCloud/codedeploy/aws"
  version = "~> 1.0"

  details = local.details
  name    = "example-web-site"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.site_deploy.metadata.iam_role.arn` for the service role's ARN, or `module.site_deploy.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`.

- [Basic application](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/tree/main/examples/basic): an application for EC2 instances, and its service role, with only the required inputs.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/tree/main/examples/complete): an application with a revision bucket and log groups created in the same run, and a deployment group that uses the service role.

## Things to know

### Deployment groups and the service role

A deployment group says where to deploy, and CodeDeploy acts with the deployment group's service role. Pass `metadata.iam_role.arn` as each deployment group's `service_role_arn`. Every deployment group of the application can share the role.

The managed policy covers what CodeDeploy needs for most deployments. Some setups need more: for example, a deployment to an EC2 Auto Scaling group that uses a launch template also needs `ec2:RunInstances`, `ec2:CreateTags` and `iam:PassRole`. Add those to the role yourself with an `aws_iam_role_policy` that names `metadata.iam_role.name`, scoped to the resources the deployment uses.

### The revision bucket

`s3_bucket` names the bucket that holds the application's revisions. The module only records it in `metadata.s3_bucket`: it does not create, read or change the bucket, so the bucket can be created in the same run, as in the complete example. CodeDeploy reads revisions only from a bucket in the application's Region, so create it there.

CodeDeploy itself does not read the bucket on EC2 and on-premises deployments: the CodeDeploy agent on each instance downloads the revision. Give the instances' IAM role `s3:GetObject` on `<arn>/<path>/*`, using the `arn` and `path` in `metadata.s3_bucket`.

### Names

The module is meant for one application per scope, purpose and environment in a Region, and names the service role from them: `<scope abbr>-<purpose abbr>-<environment abbr>-<Region abbr>-codedeploy`, such as `automate_the_cloud-web_site-production-use1-codedeploy`. Two calls with the same `details` in the same Region would need the same role name, and the second apply would fail; give each application its own `purpose` instead.

IAM allows role names of up to 64 characters. The plan fails with a clear message when the name would be longer; set shorter `scope_abbr`, `purpose_abbr` or `environment_abbr` in `details`, for example `environment_abbr = "prd"`.

### Changing the application

Changing `name` renames the application in place: its ID, deployment groups and deployment history are kept, and Terraform updates the `app_name` of deployment groups that reference it. Because of an AWS provider bug, `metadata.codedeploy_app.arn` still shows the old name until the next plan or apply refreshes it; `terraform apply -refresh-only` updates it at once.

Changing `compute_platform` replaces the application, because CodeDeploy cannot change an application's platform. Deleting the old application also deletes its deployment groups and deployment history, but the plan shows only the application being replaced: Terraform creates the deployment groups again only on the next apply. A deployment group for one platform does not fit another, so change `compute_platform` together with the deployment groups' settings, and run the apply twice.

Changing `details` renames the service role, which replaces it. Deployment groups that use it are updated in place with the new role's ARN.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-codedeploy#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The name of the CodeDeploy application, such as `my-app`, up to 100 characters and unique in the account and Region. Changing it renames the application in place.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_cloudwatch_log_group_names"></a> [cloudwatch_log_group_names](#input_cloudwatch_log_group_names)

Description: The names of the CloudWatch Logs log groups the application writes to, such as `["/my-app/access", "/my-app/error"]`. The module does not create the log groups or grant access to them: it returns the names in the `metadata` output, so that the configurations that create the instances, functions or log agent can read them from one place. Defaults to none.

Type: `list(string)`

Default: `[]`

#### <a name="input_compute_platform"></a> [compute_platform](#input_compute_platform)

Description: Where the application is deployed: `Server` (EC2 instances or on-premises servers), `ECS` (Amazon Elastic Container Service services), or `Lambda` (AWS Lambda functions). It also chooses the AWS managed policy attached to the service role. Defaults to `Server`. Changing it replaces the application.

Type: `string`

Default: `"Server"`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the application in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The service role is global, so it is created once whatever the Region.

Type: `string`

Default: `null`

#### <a name="input_s3_bucket"></a> [s3_bucket](#input_s3_bucket)

Description: An existing S3 bucket that holds the application's revisions. CodeDeploy needs it in the application's Region. The module returns its name, ARN and key prefix in the `metadata` output, so that other configurations can find it; it does not create, read or change the bucket, or grant access to it. `null`, the default, means no bucket.

- `name` - (Required) The bucket's name, such as `my-artifacts-use1`.
- `path` - (Optional) The key prefix for this application's revisions, without a leading or trailing `/`. Defaults to `codedeploy/<name>`.

Type:

```hcl
object({
    name = string
    path = optional(string)
  })
```

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the application.
- `codedeploy_app` - The application, including its `name`, `arn`, `application_id` and `compute_platform`. Deployment groups and deployment configurations take its `name`.
- `iam_role` - The service role, including its `name` and `arn`. Give the `arn` to each deployment group as its `service_role_arn`.
- `iam_role_policy_attachment` - The AWS managed policy attached to the service role: its `policy_arn` and `role`.
- `s3_bucket` - The revision bucket's `bucket` (name) and `arn`, and `path`, the key prefix for this application's revisions. `null` unless `s3_bucket` is set.
- `cloudwatch_log_group_names` - The log group names from the input of the same name.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
