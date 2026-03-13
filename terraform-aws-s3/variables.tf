variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}


variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "bucket_purpose" {
  description = "Purpose of the bucket"
  type        = string
  default     = "assets"
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Number of days after which objects expire"
  type        = number
  default     = 0
}

variable "force_destroy" {
  description = "Allow Terraform to delete bucket even if it has objects"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
