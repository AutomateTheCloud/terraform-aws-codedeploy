# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "cloudwatch_log_group_names" {
  description = <<-EOT
    The names of the CloudWatch Logs log groups the application writes to, such as `["/my-app/access", "/my-app/error"]`. The module does not create the log groups or grant access to them: it returns the names in the `metadata` output, so that the configurations that create the instances, functions or log agent can read them from one place. Defaults to none.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for n in var.cloudwatch_log_group_names : can(regex("^[-._/#A-Za-z0-9]{1,512}$", n))])
    error_message = "Each log group name must be 1 to 512 characters: letters, numbers, and . _ - / #."
  }
}

variable "compute_platform" {
  description = <<-EOT
    Where the application is deployed: `Server` (EC2 instances or on-premises servers), `ECS` (Amazon Elastic Container Service services), or `Lambda` (AWS Lambda functions). It also chooses the AWS managed policy attached to the service role. Defaults to `Server`. Changing it replaces the application.
  EOT
  type        = string
  default     = "Server"
  nullable    = false

  validation {
    condition     = contains(["Server", "ECS", "Lambda"], var.compute_platform)
    error_message = "compute_platform must be \"Server\", \"ECS\" or \"Lambda\"."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-codedeploy#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "name" {
  description = <<-EOT
    The name of the CodeDeploy application, such as `my-app`, up to 100 characters and unique in the account and Region. Changing it renames the application in place.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100 && trimspace(var.name) == var.name
    error_message = "name must be 1 to 100 characters, with no leading or trailing spaces."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the application in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module. The service role is global, so it is created once whatever the Region.
  EOT
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = <<-EOT
    An existing S3 bucket that holds the application's revisions. CodeDeploy needs it in the application's Region. The module returns its name, ARN and key prefix in the `metadata` output, so that other configurations can find it; it does not create, read or change the bucket, or grant access to it. `null`, the default, means no bucket.

    - `name` - (Required) The bucket's name, such as `my-artifacts-use1`.
    - `path` - (Optional) The key prefix for this application's revisions, without a leading or trailing `/`. Defaults to `codedeploy/<name>`.
  EOT
  type = object({
    name = string
    path = optional(string)
  })
  default = null

  validation {
    condition     = var.s3_bucket == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.s3_bucket.name))
    error_message = "s3_bucket.name must be an S3 bucket name: 3 to 63 lowercase letters, numbers, periods and hyphens."
  }

  validation {
    condition     = try(var.s3_bucket.path, null) == null || can(regex("^[^/].*[^/]$|^[^/]$", var.s3_bucket.path))
    error_message = "s3_bucket.path must not start or end with /."
  }
}
