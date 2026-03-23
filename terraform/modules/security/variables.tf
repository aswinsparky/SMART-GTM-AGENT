variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID (ECS tasks allow ingress from this)"
  type        = string
}
