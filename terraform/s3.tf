# S3 bucket and object-access configuration for product images.
#
# Move the existing S3 resources into this file.
# Preserve their Terraform resource names and current settings.

# Creates TechSahel S3 bucket
resource "aws_s3_bucket" "techsahel" {
  bucket = "${lower(var.project_name)}-bucket-product-images"
  tags = {
    Name = "${var.project_name}-bucket-product-images"
  }
}

# Making the bucket public
resource "aws_s3_bucket_public_access_block" "techsahel" {
  bucket = aws_s3_bucket.techsahel.id

  block_public_acls       = true  # Deny usage of new public ACLs
  block_public_policy     = false # Allow defining a Bucket policy 
  ignore_public_acls      = true  # Ignore existing public ACLs
  restrict_public_buckets = false # Allow the bucket to be consider as Public
}

# Defines the bucket policy
resource "aws_s3_bucket_policy" "techsahel" {
  bucket = aws_s3_bucket.techsahel.id

  # Prevents adding this resource before public policies were applied
  depends_on = [aws_s3_bucket_public_access_block.techsahel]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadProductImages"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.techsahel.arn}/images/*"
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "techsahel" {
  bucket = aws_s3_bucket.techsahel.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}