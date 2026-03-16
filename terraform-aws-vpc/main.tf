

# --- Locals (Reusable computed names) ---
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Convert lists to maps for for_each - maps subnets to their AZ
  public_subnet_map  = zipmap(var.public_subnet_cidrs, var.availability_zones)
  private_subnet_map = zipmap(var.private_subnet_cidrs, var.availability_zones)

  # For NAT gateway - map AZs to public subnet CIDRs
  nat_gateway_map = var.enable_nat_gateway ? (
    var.single_nat_gateway
    ? { "single" = var.public_subnet_cidrs[0] }
    : zipmap(var.availability_zones, var.public_subnet_cidrs)
  ) : {}
}

# --- VPC (The Compound) ---
# All resources live inside this virtual network
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# --- Internet Gateway (Main Gate to Internet) ---
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# --- Public Subnets ---
# for_each uses CIDR as key - stable identity, safe to add/remove subnets
# kubernetes tags are MANDATORY for EKS to find and use these subnets
resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.key
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                             = "${local.name_prefix}-public-${each.value}"
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${local.name_prefix}-eks" = "shared"
  })
}

# --- Private Subnets ---
# No public IP - resources here are hidden from internet
# kubernetes tags are MANDATORY for EKS internal load balancers

resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.key
  availability_zone = each.value

  tags = merge(var.tags, {
    Name                                             = "${local.name_prefix}-private-${each.value}"
    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/${local.name_prefix}-eks" = "shared"
  })
}

# --- Public Route Table ---
# Directs all internet traffic through the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  for_each = local.public_subnet_map

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# --- NAT Gateway (One Way Door for Private Subnets) ---
# Elastic IP for each NAT Gateway
resource "aws_eip" "nat" {
  for_each = local.nat_gateway_map
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-nat-eip-${each.key}"
  })
}

# NAT Gateway - single in dev, one per AZ in prod
resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateway_map

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value].id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-natgw-${each.key}"
  })

  # Must wait for internet gateway before creating NAT
  depends_on = [aws_internet_gateway.this]
}

# --- Private Route Tables ---
# One route table per private subnet - for_each gives each a stable identity
resource "aws_route_table" "private" {
  for_each = local.private_subnet_map
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-private-rt-${each.value}"
  })
}

# Route private subnet traffic through NAT Gateway
resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? local.private_subnet_map : {}

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"

  # single NAT = always use "single" key, multiple NATs = use matching AZ
  nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this["single"].id : aws_nat_gateway.this[each.value].id
}

# Associate each private subnet with its own route table
resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}