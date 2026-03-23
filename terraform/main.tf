# Root module - wires VPC, ALB, security, RDS, secrets, ECS, ECR, frontend

data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  project_name         = var.project_name
  availability_zone_count = 2
}

# ------------------------------------------------------------------------------
# ECR
# ------------------------------------------------------------------------------
module "ecr" {
  source        = "./modules/ecr"
  project_name  = var.project_name
}

# ------------------------------------------------------------------------------
# ALB (needs VPC). target_type = "instance" for EC2, "ip" for ECS
# ------------------------------------------------------------------------------
module "alb" {
  source             = "./modules/alb"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  target_type        = var.backend_type == "ec2" ? "instance" : "ip"
}

# ------------------------------------------------------------------------------
# Security groups (ECS tasks + RDS), needs ALB SG
# ------------------------------------------------------------------------------
module "security" {
  source                  = "./modules/security"
  project_name            = var.project_name
  vpc_id                  = module.vpc.vpc_id
  alb_security_group_id   = module.alb.alb_security_group_id
}

# ------------------------------------------------------------------------------
# RDS (needs private subnets + RDS SG)
# ------------------------------------------------------------------------------
module "rds" {
  source                 = "./modules/rds"
  project_name           = var.project_name
  private_subnet_ids     = module.vpc.private_subnet_ids
  rds_security_group_id  = module.security.rds_security_group_id
  db_instance_class      = var.db_instance_class
  environment            = var.environment
}

# ------------------------------------------------------------------------------
# Secrets (DATABASE_URL from RDS, OPENAI_API_KEY placeholder)
# ------------------------------------------------------------------------------
module "secrets" {
  source                      = "./modules/secrets"
  project_name                = var.project_name
  database_url                = module.rds.connection_string
  openai_api_key_secret_name  = var.openai_api_key_secret_name
  depends_on                  = [module.rds]
}

# ------------------------------------------------------------------------------
# ECS (when backend_type = ecs): Fargate runs backend container
# ------------------------------------------------------------------------------
module "ecs" {
  count                           = var.backend_type == "ecs" ? 1 : 0
  source                          = "./modules/ecs"
  project_name                    = var.project_name
  aws_region                      = var.aws_region
  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnet_ids
  ecs_tasks_security_group_id     = module.security.ecs_tasks_security_group_id
  target_group_arn                = module.alb.target_group_arn
  ecr_repository_url               = module.ecr.repository_url
  database_url_secret_arn         = module.secrets.database_url_secret_arn
  openai_api_key_secret_arn       = module.secrets.openai_api_key_secret_arn
  ecs_cpu                         = var.ecs_cpu
  ecs_memory_mb                   = var.ecs_memory_mb
  ecs_desired_count               = var.ecs_desired_count
  mock_mode                       = var.backend_mock_mode
  llm_provider                    = var.backend_llm_provider
  bedrock_model_id                = var.backend_bedrock_model_id
}

# ------------------------------------------------------------------------------
# EC2 backend (when backend_type = ec2): EC2 + ASG behind ALB, same backend image
# ------------------------------------------------------------------------------
module "ec2_backend" {
  count                      = var.backend_type == "ec2" ? 1 : 0
  source                     = "./modules/ec2_backend"
  project_name               = var.project_name
  aws_region                  = var.aws_region
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  backend_security_group_id   = module.security.ecs_tasks_security_group_id
  target_group_arn            = module.alb.target_group_arn
  ecr_repository_url          = module.ecr.repository_url
  database_url_secret_arn     = module.secrets.database_url_secret_arn
  openai_api_key_secret_arn   = module.secrets.openai_api_key_secret_arn
  instance_type               = var.ec2_instance_type
  min_size                    = var.ec2_min_size
  max_size                    = var.ec2_max_size
  mock_mode                   = var.backend_mock_mode
}

# ------------------------------------------------------------------------------
# CloudFront in front of ALB so API is HTTPS (avoids mixed-content block in browser)
# ------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "api" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} API"
  price_class         = "PriceClass_100"
  origin {
    domain_name = module.alb.alb_dns_name
    origin_id   = "ALB-${var.project_name}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "ALB-${var.project_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ------------------------------------------------------------------------------
# Frontend (S3 + CloudFront)
# ------------------------------------------------------------------------------
module "frontend" {
  source        = "./modules/frontend"
  project_name  = var.project_name
  account_id    = data.aws_caller_identity.current.account_id
  domain_name   = var.domain_name
}
