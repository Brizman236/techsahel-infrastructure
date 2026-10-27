variable "aws_region" {
  description = "AWS Region for TechSahel Lab"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR range for the TechSahel Lab VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project Name used for ressource naming"
  type        = string
  default     = "TechSahel"
}

variable "az_a" {
  description = "First Availabily Zone for TechSahel"
  type        = string
  default     = "eu-west-3a"
}

variable "az_b" {
  description = "Second Availability Zone for TechSahel"
  type        = string
  default     = "eu-west-3b"
}

variable "catalog_app_user_secret_arn" {
  description = "TechSahel Application runtime database user ARN secret"
  type        = string
  default     = "arn:aws:secretsmanager:eu-west-3:936719391688:secret:techsahel/production/database-??????"
}

variable "flask_signing_key_arn" {
  description = "TechSahel Flask App signing key secret ARN"
  type        = string
  default     = "arn:aws:secretsmanager:eu-west-3:936719391688:secret:techsahel/production/flask-??????"
}

variable "app_config_params" {
  description = "TechSahel Application Parameters Path"
  type        = string
  default     = "arn:aws:ssm:eu-west-3:936719391688:parameter/techsahel/production/*"
}