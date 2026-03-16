# --- Project Identity ---
variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

# --- Environment with Validation ---
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# --- Bucket Names ---
# Add as many bucket purposes as needed
# Each creates a separate bucket: teleios-light-dev-assets, teleios-light-dev-logs etc
variable "bucket_names" {
  description = "List of bucket purposes to create"
  type        = list(string)
  default     = ["assets"]
}

# --- Shared Settings ---
# These settings apply to ALL buckets
variable "enable_versioning" {
  description = "Enable versioning on all buckets"
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Number of days after which objects expire (0 = never)"
  type        = number
  default     = 0
}

variable "force_destroy" {
  description = "Allow Terraform to delete buckets even if they have objects"
  type        = bool
  default     = false
}

# --- Additional Tags ---
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}