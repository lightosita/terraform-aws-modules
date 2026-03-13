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
  description = "VPC ID where EC2 instances will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EC2 instances"
  type        = list(string)
}

# --- EC2 Instance Configuration ---
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (leave empty for latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "SSH key pair name (optional)"
  type        = string
  default     = ""
}

# --- Auto Scaling Configuration ---
# Controls how many servers run at any given time
variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

# --- Additional Tags ---
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}