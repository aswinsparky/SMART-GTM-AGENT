variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "account_id" {
  description = "AWS account ID (for unique bucket name)"
  type        = string
}

variable "domain_name" {
  description = "Optional custom domain for CloudFront"
  type        = string
  default     = ""
}
