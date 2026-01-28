# Subnets Module - Creates public, private, and data subnets with route tables

locals {
  # Subnet CIDR calculations for 2 AZs:
  # Public:  10.0.1.0/24, 10.0.2.0/24
  # Private: 10.0.11.0/24, 10.0.12.0/24
  # Data:    10.0.21.0/24, 10.0.22.0/24
  public_subnets  = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnets = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 11)]
  data_subnets    = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 21)]
}

# ============================================================================
# PUBLIC SUBNETS
# ============================================================================
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = var.vpc_id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# PRIVATE SUBNETS (Application Layer)
# ============================================================================
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = var.vpc_id
  cidr_block              = local.private_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
    Tier = "private"
  })
}

# Private Route Table (no NAT Gateway - uses VPC Endpoints instead)
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================================
# DATA SUBNETS (Database Layer)
# ============================================================================
resource "aws_subnet" "data" {
  count = length(var.availability_zones)

  vpc_id                  = var.vpc_id
  cidr_block              = local.data_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-${var.availability_zones[count.index]}"
    Tier = "data"
  })
}

# Data Route Table (local only - no internet access)
resource "aws_route_table" "data" {
  vpc_id = var.vpc_id

  # No additional routes - only local VPC traffic allowed

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-rt"
  })
}

resource "aws_route_table_association" "data" {
  count = length(aws_subnet.data)

  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}
