output "database_url_secret_arn" {
  description = "Secrets Manager ARN for DATABASE_URL"
  value       = aws_secretsmanager_secret.database_url.arn
}

output "openai_api_key_secret_arn" {
  description = "Secrets Manager ARN for OPENAI_API_KEY"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}
