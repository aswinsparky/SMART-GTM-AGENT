output "target_group_arn" {
  description = "Target group ARN for ECS"
  value       = aws_lb_target_group.backend.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "listener_arn" {
  description = "ALB listener ARN"
  value       = aws_lb_listener.http.arn
}
