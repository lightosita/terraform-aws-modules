
# terraform-aws-modules

  Enterprise Terraform Module Library — Production-grade, reusable AWS infrastructure modules for the Teleios e-commerce platform.

  ---

  ## Project Overview

  This repository contains a library of 6 self-contained Terraform modules that enable any engineer to deploy production-grade AWS
  infrastructure with a single command. Each module is independently reusable, follows the DRY principle, and is designed for use across
  development, staging, and production environments.

  **Naming Convention:** All resources follow the pattern:

  teleios-<your-first-name>-<environment>-<resource>

  Examples: `teleios-light-dev-vpc`, `teleios-light-prod-eks`

  ---

  ## Target Architecture

  Internet
      |
      v
  [ALB - Public Subnet]
      |
      v
  [EKS Worker Nodes - Private Subnet]
      |
      |--- [RDS PostgreSQL - Private Subnet]
      |--- [ElastiCache Redis - Private Subnet]
      |--- [EC2 Auto Scaling Group - Private Subnet]
      |--- [S3 Buckets]

  ### Architecture Layers

  | Layer      | Services |
  |-------     |----------|
  | Networking | VPC, Public/Private Subnets, NAT Gateway, ALB, Security Groups |
  | Compute    | EKS Cluster with Managed Node Groups + EC2 Auto Scaling |
  | Data       | RDS PostgreSQL, ElastiCache Redis |
  | Storage    | S3 Buckets with versioning and encryption |

  ## Modules

  ### 1. terraform-aws-vpc

  **Purpose:** Foundation networking layer. All other modules depend on this.

  **Creates:**
  - VPC with configurable CIDR
  - Public and private subnets across multiple availability zones
  - Internet Gateway
  - NAT Gateway (single or one per AZ)
  - Route tables and associations
  - Kubernetes-required subnet tags for EKS

  **Key Design Decision:** Kubernetes subnet tags (`kubernetes.io/role/elb`) are mandatory — without them EKS cannot create load balancers.

  ### 2. terraform-aws-s3

  **Purpose:** Object storage for product images, static files, and backups.

  **Creates:**
  - S3 bucket with computed naming
  - Versioning (file history and recovery)
  - AES256 server-side encryption
  - Lifecycle policies for cost management

  **Key Design Decision:** AES256 encryption is mandatory for GDPR and PCI-DSS compliance on any e-commerce platform handling customer data.

  ### 3. terraform-aws-rds

  **Purpose:** Primary relational database (PostgreSQL) for orders, products, and user data.

  **Creates:**
  - RDS PostgreSQL 15.4 instance
  - DB subnet group (private subnets only)
  - Security group (port 5432, VPC-internal only)
  - Automated backups with configurable retention
  - Storage autoscaling (doubles automatically)
  - Multi-AZ support for high availability

  **Key Design Decision:** RDS is deployed in private subnets only — no direct internet access. Storage autoscaling prevents manual intervention
   when database grows.

  ### 4. terraform-aws-redis

  **Purpose:** In-memory caching for sessions, shopping cart data, and frequently accessed content.

  **Creates:**
  - ElastiCache Redis 7.0 cluster
  - Subnet group (private subnets only)
  - Security group (port 6379, VPC-internal only)
  - Configurable node count per environment

  **Key Design Decision:** Redis is cache — not primary storage. No deletion protection needed as losing cache only causes temporary performance
   impact, not data loss.

  ### 5. terraform-aws-ec2

  **Purpose:** Auto-scaling web/app servers for the e-commerce application.

  **Creates:**
  - Launch Template with dynamic AMI selection (always latest Amazon Linux 2023)
  - Auto Scaling Group with configurable min/max/desired
  - Security group (ports 80, 443, 22)
  - User data bootstrap script (installs and starts Apache)

  **Key Design Decision:** Launch Templates with ASG instead of single instances — infrastructure automatically responds to traffic, replacing
  unhealthy instances and scaling based on demand.

  ### 6. terraform-aws-eks

  **Purpose:** Managed Kubernetes cluster for running containerised applications.

  **Creates:**
  - EKS Cluster (AWS-managed control plane)
  - IAM roles for cluster and worker nodes
  - Managed Node Group with auto-scaling
  - Security groups for cluster, nodes, and ALB
  - Application Load Balancer (public-facing)

  **Key Design Decision:** Worker nodes live in private subnets — only the ALB is public-facing. `depends_on` ensures IAM roles exist before EKS
   tries to use them, preventing race conditions.

  ---

  ## Module Dependency Flow

  terraform-aws-vpc (outputs: vpc_id, subnet_ids, vpc_cidr)
          |
          |--- terraform-aws-eks   (needs: vpc_id, private_subnet_ids, public_subnet_ids)
          |--- terraform-aws-ec2   (needs: vpc_id, private_subnet_ids)
          |--- terraform-aws-rds   (needs: vpc_id, private_subnet_ids, vpc_cidr)
          |--- terraform-aws-redis (needs: vpc_id, private_subnet_ids, vpc_cidr)

  terraform-aws-s3 (independent — no VPC dependency)

  ---

  ## Environment Configuration

  Each module supports 3 environments with different cost/resilience tradeoffs:

  | Setting            | Dev          | Staging      | Prod          |
  |--------------------|--------------|--------------|---------------|
  | NAT Gateway        | Single       | Single       | One per AZ    |
  | RDS Instance       | db.t3.micro  | db.t3.small  | db.t3.medium  |
  | Multi-AZ RDS       | No           | Yes          | Yes           |
  | Backup Retention   | 7 days       | 7 days       | 30 days       |
  | EKS Nodes          | t3.medium x1 | t3.medium x2 | t3.large x3   |
  | Redis Nodes        | 1            | 1            | 2+            |
  | Deletion Protection| No           | No           | Yes           |

  ---

  ## Security Standards

  - All databases deployed in private subnets only
  - Security groups follow principle of least privilege — only required ports open
  - Database passwords stored in Terraform Cloud as sensitive variables — never in code
  - All S3 data encrypted at rest with AES256
  - RDS storage encrypted at rest
  - `lifecycle { create_before_destroy = true }` on all security groups for zero-downtime replacements

  ---

  ## Repository Structure

  terraform-aws-modules/
  ├── terraform-aws-vpc/
  │   ├── main.tf

  └── .gitignore

  ---

  ## Usage

  Each module is called from the implementation repository (`e-commerce-infrastructure-aws`) like this:

  ```hcl
  module "vpc" {
    source = "github.com/lightosita/terraform-aws-modules//terraform-aws-vpc"

    project_name         = "teleios-light"
    environment          = "dev"
    vpc_cidr             = "10.0.0.0/16"
    availability_zones   = ["us-east-1a", "us-east-1b"]
    public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
    enable_nat_gateway   = true
    single_nat_gateway   = true
  }

  module "rds" {
    source = "github.com/lightosita/terraform-aws-modules//terraform-aws-rds"

    project_name       = "teleios-light"
    environment        = "dev"
    vpc_id             = module.vpc.vpc_id
    private_subnet_ids = module.vpc.private_subnet_ids
    vpc_cidr           = module.vpc.vpc_cidr
    db_password        = var.db_password  # stored in Terraform Cloud
  }

  ---
  Module Quality Standards

  Every module in this library meets the following standards:

  - Input validation — environment variables validated with contains() checks
  - Sensitive variables — passwords marked sensitive = true
  - Consistent naming — all resources follow teleios-<name>-<env>-<resource> convention
  - DRY principle — locals block computes reusable name prefix
  - Flexible tagging — merge(var.tags, {...}) allows additional tags per environment
  - Zero downtime — lifecycle { create_before_destroy = true } on all security groups
  - Self-contained — each module creates its own security groups internally
  - Validated — all modules pass terraform validate and terraform fmt

  ---
  Cost Management

  IMPORTANT: Always destroy AWS resources immediately after verifying a successful deployment.

  # Deploy
  terraform apply

  # Verify everything works and take screenshots

  # Destroy immediately
  terraform destroy

  Resources like EKS clusters, RDS instances, NAT Gateways, and ALBs cost real money every hour. Never leave resources running overnight or over
   weekends.

  ---
  References

  - https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  - https://developer.hashicorp.com/terraform/language
  - https://aws.github.io/aws-eks-best-practices/
  - https://docs.aws.amazon.com/vpc/latest/userguide/

  ---
  Author

  Light Osita — Teleios DevOps Programme

  GitHub: https://github.com/lightosita