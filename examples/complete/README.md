# Complete application

A CodeDeploy application for EC2 instances that uses most of the module's inputs:

- A private, encrypted, versioned S3 bucket for the application's revisions, which deletes old versions after 30 days, created with the [Automate the Cloud S3 bucket module](https://registry.terraform.io/modules/AutomateTheCloud/s3_bucket/aws) in the same run, in the application's Region, where CodeDeploy needs it.
- Two CloudWatch Logs log groups, kept for 30 days, whose names the module returns in its `metadata` output.
- A deployment group, `web`, that uses the module's service role and deploys to EC2 instances tagged `CodeDeployGroup = example-complete-web`, one at a time, rolling back on failure.

No instances are created, so a deployment has nothing to do, and the example is safe to apply. To try a deployment, launch an instance with the CodeDeploy agent and that tag, give its instance profile read access to the bucket, and upload a revision to the `revision_location` output.

## Run it

```shell
terraform init
terraform apply
```

Remove it with `terraform destroy`. Empty the bucket first, including old versions, if you uploaded revisions: the S3 bucket module does not delete a bucket that holds objects.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (~> 3.0)

### Outputs

The following outputs are exported:

#### <a name="output_application_name"></a> [application_name](#output_application_name)

Description: Name of the CodeDeploy application

#### <a name="output_revision_location"></a> [revision_location](#output_revision_location)

Description: Where to upload revisions: s3://<bucket>/<path>/
<!-- END_TF_DOCS -->
