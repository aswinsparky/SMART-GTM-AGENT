resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${var.project_name}/database-url"
  description             = "PostgreSQL connection string for Smart GTM Agent"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = var.database_url
}

resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = var.openai_api_key_secret_name
  description             = "OpenAI API key for Smart GTM Agent (set value manually in AWS Console)"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "openai_api_key_placeholder" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = "REPLACE_ME"
}
