# --- Project Identity ---
variable "project_name" {
  description = "Project name used in resource naming (e.g., teleios-light)"
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

# --- VPC CIDR with Validation ---
# 10.0.0.0/16 gives you 65,536 IP addresses
variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# --- Availability Zones ---
variable "availability_zones" {
  description = "List of AZs to deploy into (e.g., ['us-east-1a', 'us-east-1b'])"
  type        = list(string)
}

# --- Subnet CIDRs ---
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

# --- NAT Gateway Configuration ---
# enable_nat_gateway costs ~$32/month - disable in dev to save money
variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway"
  type        = bool
  default     = true
}

# single_nat_gateway saves cost but less resilient
# dev = true (one NAT), prod = false (one NAT per AZ)
variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ"
  type        = bool
  default     = true
}

# --- Additional Tags ---
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}