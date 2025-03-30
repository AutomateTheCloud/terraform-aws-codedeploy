variable "cloudwatch_log_group_names" {
  description = "CodeDeploy Application CloudWatch Log Group Names"
  type        = list(any)
  default     = []
}

variable "compute_platform" {
  description = "Compute Platform (Server, ECS, Lambda)"
  type        = string
  default     = ""
}

variable "name" {
  description = "The name of the application"
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "S3 Bucket for CodeDeploy artifacts"
  type        = string
  default     = ""
}