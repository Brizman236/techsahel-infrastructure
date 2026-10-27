# Security Groups for the TechSahel Application Server
## Security Group for inbound http traffic
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Control inbound and outbound traffic for the TechSahel EC2 instance"
  vpc_id      = aws_vpc.techsahel.id

  ingress {
    description = "HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound IPv4 trafic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  # SSH is kept closed. The instance will be managed through AWS System Manager

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }

}

# Security Group for PostgreSQL database
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allows PostgreSQL traffic only from TechSahel EC2 security Group"
  vpc_id      = aws_vpc.techsahel.id

  ingress {
    description     = "PostgreSQL from TechSahel EC2 security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # No inbound database access from the public internet.

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}