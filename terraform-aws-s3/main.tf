locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- S3 Buckets ---
resource "aws_s3_bucket" "this" {
  for_each = toset(var.bucket_names)

  bucket        = "${local.name_prefix}-${each.key}"
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-${each.key}"
    Environment = var.environment
    Project     = var.project_name
    Purpose     = each.key
    ManagedBy   = "terraform"
  })
}

# --- Versioning ---
resource "aws_s3_bucket_versioning" "this" {
  for_each = toset(var.bucket_names)

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# --- Encryption ---
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = toset(var.bucket_names)

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Lifecycle Policy ---
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = var.lifecycle_expiration_days > 0 ? toset(var.bucket_names) : toset([])

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    id = "expire-objects-${each.key}"
    filter {}
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}