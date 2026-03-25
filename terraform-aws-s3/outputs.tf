# --- Bucket Names ---
output "bucket_names" {
  description = "Map of bucket purpose to bucket name"
  value       = { for k, v in aws_s3_bucket.this : k => v.id }
}

# --- Bucket ARNs ---
output "bucket_arns" {
  description = "Map of bucket purpose to bucket ARN"
  value       = { for k, v in aws_s3_bucket.this : k => v.arn }
}

# --- Bucket Domain Names ---
output "bucket_domain_names" {
  description = "Map of bucket purpose to bucket domain name"
  value       = { for k, v in aws_s3_bucket.this : k => v.bucket_domain_name }
}