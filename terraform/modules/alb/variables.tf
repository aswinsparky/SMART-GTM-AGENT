variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/api-key"
}

variable "target_type" {
  description = "Target group target type: 'ip' for ECS Fargate, 'instance' for EC2"
  type        = string
  default     = "ip"
}
