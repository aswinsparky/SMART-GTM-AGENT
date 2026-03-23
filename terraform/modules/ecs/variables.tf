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
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "ecr_repository_url" {
  description = "ECR repository URL for backend image"
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

variable "ecs_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "ecs_memory_mb" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks"
  type        = number
  default     = 1
}

variable "mock_mode" {
  description = "If true, set MOCK_MODE=1 so backend returns mock plans without calling OpenAI"
  type        = bool
  default     = false
}

variable "llm_provider" {
  description = "LLM to use: 'openai' or 'bedrock'. Bedrock uses ECS task role; no API key needed."
  type        = string
  default     = "openai"
}

variable "bedrock_model_id" {
  description = "Bedrock model ID when llm_provider=bedrock (e.g. anthropic.claude-3-haiku-20240307-v1:0)"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}
