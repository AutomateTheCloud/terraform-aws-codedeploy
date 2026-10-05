# Basic application

A CodeDeploy application for EC2 instances or on-premises servers, named `example-basic`, and the IAM service role that its deployment groups use. Only the required inputs are set.

The application costs nothing until you deploy to it. To deploy, add a deployment group that names the application and the service role, as the [complete example](https://github.com/AutomateTheCloud/terraform-aws-codedeploy/tree/main/examples/complete) does.

## Run it

```shell
terraform init
terraform apply
```

Remove it with `terraform destroy`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Outputs

The following outputs are exported:

#### <a name="output_application_name"></a> [application_name](#output_application_name)

Description: Name of the CodeDeploy application

#### <a name="output_service_role_arn"></a> [service_role_arn](#output_service_role_arn)

Description: ARN of the service role, for a deployment group's service_role_arn
<!-- END_TF_DOCS -->
