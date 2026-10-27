output "vpc_id" {
  description = "ID of the TechSahel VPC"
  value       = aws_vpc.techsahel.id
}

output "vpc_cidr" {
  description = "CIDR block of he TechSahel VPC"
  value       = aws_vpc.techsahel.cidr_block
}

output "public_a_id" {
  description = "ID of the TechSahel VPC's Public Subnet A"
  value       = aws_subnet.public_a.id
}


output "private_a_id" {
  description = "ID of the TechSahel VPC's Private Subnet A"
  value       = aws_subnet.private_a.id
}

output "private_b_id" {
  description = "ID of the TechSahel VPC's Private Subnet B"
  value       = aws_subnet.private_b.id
}

output "igw_id" {
  description = "ID of the TechSahel VPC's Internet Gateway"
  value       = aws_internet_gateway.techsahel.id
}

output "app_server_id" {
  description = "ID of TechSahel App Server"
  value       = aws_instance.techsahel.id
}

output "rds_endpoint" {
  description = "TechSahel RDS endpoint hostname"
  value       = aws_db_instance.techsahel.address
}

output "rds_port" {
  description = "TechSahel Postgres port"
  value       = aws_db_instance.techsahel.port
}

output "rds_database_name" {
  description = "TechSahel Database name"
  value       = aws_db_instance.techsahel.db_name
}

output "rds_master_secret_arn" {
  description = "ARN of the RDS-managed master password secret"
  value       = aws_db_instance.techsahel.master_user_secret[0].secret_arn
}

output "s3_bucket" {
  description = "S3 bucket containing TechSahel product images"
  value       = aws_s3_bucket.techsahel.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the TechSahel S3 Bucket"
  value       = aws_s3_bucket.techsahel.arn
}

output "s3_bucket_endpoint" {
  description = "TechSahel S3 bucket endpoint"
  value       = aws_s3_bucket.techsahel.bucket_regional_domain_name
}