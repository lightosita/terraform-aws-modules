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
  description = "VPC ID where EKS will be deployed (from VPC module output)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes (from VPC module output)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB (from VPC module output)"
  type        = list(string)
}

# --- EKS Cluster Configuration ---
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

# --- Node Group Configuration ---
# Worker nodes are the actual servers that run your containers
variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

# --- Additional Tags ---
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}