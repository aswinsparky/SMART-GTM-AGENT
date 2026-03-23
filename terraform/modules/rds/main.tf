resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = var.db_instance_class
  db_name        = "gtm"
  username       = "gtmadmin"
  password       = random_password.db.result
  allocated_storage          = var.allocated_storage
  storage_encrypted          = true
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [var.rds_security_group_id]
  multi_az                   = false
  publicly_accessible        = false
  skip_final_snapshot        = var.environment != "prod"
  deletion_protection        = var.environment == "prod"
}
