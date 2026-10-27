# Allows EC2 to assume its role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

# IAM role use by TechSahel EC2 instance
resource "aws_iam_role" "ec2_ssm" {
  name               = "${var.project_name}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json


  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

# Grants the instance the permissions needed for System Manager
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Make the IAM role attachable to an EC2 instance
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_ssm.name

  tags = {
    Name = "${var.project_name}-ec2-instance-profile"
  }
}

data "aws_iam_policy_document" "ec2_read_rds_secret" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:DescribeSecrets"
    ]
    resources = [var.catalog_app_user_secret_arn, var.flask_signing_key_arn]
  }
}

resource "aws_iam_role_policy" "ec2_read_rds_secret" {
  name   = "${var.project_name}-ec2-read-rds-secret"
  role   = aws_iam_role.ec2_ssm.id
  policy = data.aws_iam_policy_document.ec2_read_rds_secret.json
}

data "aws_iam_policy_document" "ec2_read_app_config" {
  statement {
    sid    = "ReadTechSahelProductionParameters"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterByPath",
      "ssm:GetParametersByPath"
    ]

    resources = [
      var.app_config_params
    ]
  }
}

# Attaches the policy to our ec2 instance
resource "aws_iam_role_policy" "ec2_read_app_config" {
  name   = "${var.project_name}-ec2-read-app-config"
  role   = aws_iam_role.ec2_ssm.id
  policy = data.aws_iam_policy_document.ec2_read_app_config.json
}