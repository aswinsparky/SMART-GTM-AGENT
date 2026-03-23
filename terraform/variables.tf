variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "smart-gtm-agent"
}

variable "environment" {
  description = "Environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "ecs_cpu" {
  description = "Fargate task CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "ecs_memory_mb" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "openai_api_key_secret_name" {
  description = "Name of the Secrets Manager secret containing OPENAI_API_KEY (create and set value manually)"
  type        = string
  default     = "smart-gtm-agent/openai-api-key"
}

variable "domain_name" {
  description = "Optional custom domain for frontend (leave empty for CloudFront URL only)"
  type        = string
  default     = ""
}

variable "allowed_cors_origins" {
  description = "Allowed CORS origins for the API (e.g. CloudFront URL)"
  type        = list(string)
  default     = ["*"]
}

# Backend compute: "ecs" (Fargate) or "ec2" (EC2 + ASG behind ALB)
variable "backend_type" {
  description = "Backend compute: 'ecs' for ECS Fargate, 'ec2' for EC2 instances behind ALB"
  type        = string
  default     = "ecs"
}

variable "ec2_instance_type" {
  description = "EC2 instance type when backend_type = ec2"
  type        = string
  default     = "t3.micro"
}

variable "ec2_min_size" {
  description = "ASG min size when backend_type = ec2"
  type        = number
  default     = 1
}

variable "ec2_max_size" {
  description = "ASG max size when backend_type = ec2"
  type        = number
  default     = 2
}

# Set to true to use mock GTM plans (no OpenAI calls). Useful when quota exceeded or for testing.
variable "backend_mock_mode" {
  description = "If true, backend uses mock plans and does not call OpenAI (avoids quota/billing issues)"
  type        = bool
  default     = false
}

# Use 'bedrock' to call AWS Bedrock (Claude) instead of OpenAI. No API key needed; uses ECS task role.
variable "backend_llm_provider" {
  description = "LLM provider: 'openai' or 'bedrock'. Bedrock is pay-per-use (not in standard free tier)."
  type        = string
  default     = "openai"
}

variable "backend_bedrock_model_id" {
  description = "Bedrock model ID when backend_llm_provider=bedrock (e.g. Claude Haiku for lower cost)"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}
