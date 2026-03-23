variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "backend_security_group_id" {
  description = "Security group ID (allow 8000 from ALB)"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN to register instances"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL for backend image (e.g. 123456789.dkr.ecr.region.amazonaws.com/repo-name)"
  type        = string
}

variable "database_url_secret_arn" {
  description = "Secrets Manager ARN for DATABASE_URL"
  type        = string
}

variable "openai_api_key_secret_arn" {
  description = "Secrets Manager ARN for OPENAI_API_KEY"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 2
}

variable "mock_mode" {
  description = "If true, set MOCK_MODE=1 so backend returns mock plans without calling OpenAI"
  type        = bool
  default     = false
}
