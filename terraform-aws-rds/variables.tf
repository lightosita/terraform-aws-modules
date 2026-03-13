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

# --- Network Inputs (from VPC module outputs) ---
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

# --- RDS Instance Configuration ---
variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.micro for dev, db.t3.medium for prod)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

# --- Database Credentials ---
variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "ecommerce"
}

variable "db_username" {
  description = "Master database username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master database password (store in Terraform Cloud as sensitive variable)"
  type        = string
  sensitive   = true
}

# --- High Availability & Backup ---
variable "multi_az" {
  description = "Enable Multi-AZ deployment (doubles cost but provides failover)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

# --- Protection ---
variable "deletion_protection" {
  description = "Prevent accidental deletion of the database"
  type        = bool
  default     = false
}

# --- Additional Tags ---
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}