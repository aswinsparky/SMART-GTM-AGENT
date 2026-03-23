output "backend_url" {
  description = "Backend API base URL (ALB, HTTP)"
  value       = "http://${module.alb.alb_dns_name}"
}

output "backend_https_url" {
  description = "Backend API over HTTPS (CloudFront) - use for VITE_API_URL so browser does not block (no mixed content)"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}"
}

output "frontend_url" {
  description = "Frontend URL (CloudFront)"
  value       = "https://${module.frontend.cloudfront_domain_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL for backend image"
  value       = module.ecr.repository_url
}

output "frontend_bucket" {
  description = "S3 bucket name for frontend deploy"
  value       = module.frontend.bucket_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.frontend.cloudfront_distribution_id
}

output "openai_secret_arn" {
  description = "Secrets Manager secret ARN for OPENAI_API_KEY - set the value in AWS Console"
  value       = module.secrets.openai_api_key_secret_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name (only when backend_type = ecs)"
  value       = length(module.ecs) > 0 ? module.ecs[0].cluster_name : null
}

output "ecs_service_name" {
  description = "ECS service name (only when backend_type = ecs)"
  value       = length(module.ecs) > 0 ? module.ecs[0].service_name : null
}

output "ec2_asg_name" {
  description = "EC2 ASG name (only when backend_type = ec2)"
  value       = length(module.ec2_backend) > 0 ? module.ec2_backend[0].asg_name : null
}
