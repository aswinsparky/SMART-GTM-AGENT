variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "image_retention_count" {
  description = "Number of images to retain in lifecycle policy"
  type        = number
  default     = 10
}
