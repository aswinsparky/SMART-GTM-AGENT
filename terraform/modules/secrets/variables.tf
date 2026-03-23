variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "database_url" {
  description = "PostgreSQL connection string (sensitive)"
  type        = string
  sensitive   = true
}

variable "openai_api_key_secret_name" {
  description = "Secrets Manager secret name for OPENAI_API_KEY"
  type        = string
}
