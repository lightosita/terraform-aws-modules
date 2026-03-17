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

# --- Network Inputs ---
variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

# --- EKS Cluster Configuration ---
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.29"
}

# --- Node Group Configuration ---
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

# --- Cluster IAM Policies ---
# Drives for_each on aws_iam_role_policy_attachment for the cluster role
# Add or remove policies here without touching resource blocks
variable "cluster_iam_policies" {
  description = "Map of IAM policies to attach to the EKS cluster role"
  type        = map(string)
  default = {
    cluster_policy          = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    vpc_resource_controller = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  }
}

# --- Node IAM Policies ---
# Drives for_each on aws_iam_role_policy_attachment for the node role
variable "node_iam_policies" {
  description = "Map of IAM policies to attach to the EKS node role"
  type        = map(string)
  default = {
    worker_node_policy = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    cni_policy         = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    ecr_read_only      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
}

# --- Cluster Security Group Ingress Rules ---
variable "cluster_ingress_rules" {
  description = "Map of ingress rules for the EKS cluster control plane security group"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
  }))
  default = {
    https = {
      description = "Allow HTTPS from within VPC"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# --- ALB Security Group Ingress Rules ---
variable "alb_ingress_rules" {
  description = "Map of ingress rules for the ALB security group"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
  }))
  default = {
    http = {
      description = "Allow HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    https = {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}