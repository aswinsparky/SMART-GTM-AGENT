variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "availability_zone_count" {
  description = "Number of AZs to use for subnets"
  type        = number
  default     = 2
}
