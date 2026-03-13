# --- locals block(reusable) ---
locals {
  bucket_name = "teleios-${var.project_name}-${var.environment}-${var.bucket_purpose}"
}


# --- S3 Bucket Resource ---

resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name        = local.bucket_name
    Environment = var.environment
    Project     = var.project_name
    Purpose     = var.bucket_purpose
    ManagedBy   = "terraform"
  })
}

# --- Versioning ---

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}


# --- Encryption ---

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# --- Lifecycle Policy ---

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.lifecycle_expiration_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}




