
resource "aws_db_subnet_group" "techsahel" {
  name = "${lower(var.project_name)}-rds-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

resource "aws_db_instance" "techsahel" {
  identifier = "${lower(var.project_name)}-postgres"

  engine         = "postgres"
  instance_class = "db.t3.micro"
  db_name        = "product_catalog"
  username       = "catalog_admin"

  # AWS manages the master password in Secrets Manager.
  manage_master_user_password = true

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.techsahel.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Single-AZ deployment
  multi_az = false

  backup_retention_period = 1

  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = true

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
