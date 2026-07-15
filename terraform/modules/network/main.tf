data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# --- Public subnets (2 AZs) - only the ALB and NAT Gateways live here ---
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.20.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                     = "${var.project_name}-${var.environment}-public-${count.index}"
    "kubernetes.io/role/elb" = "1" # required tag for AWS Load Balancer Controller subnet discovery
  })
}

# --- Private subnets (2 AZs) - EKS nodes and RDS live here, no public IPs ---
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.20.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name                              = "${var.project_name}-${var.environment}-private-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# --- Dedicated subnets for RDS (kept separate from the EKS node subnets
# so the DB security group can scope inbound access precisely to the
# EKS node subnet CIDRs, not the whole private address space) ---
resource "aws_subnet" "database" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.20.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-${count.index}"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.project_name}-${var.environment}-igw" })
}

# One NAT Gateway per AZ for the private subnets' outbound internet
# access (pulling container images, calling AWS APIs) without exposing
# nodes with a public IP.
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.project_name}-${var.environment}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.tags, { Name = "${var.project_name}-${var.environment}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }
  tags = merge(var.tags, { Name = "${var.project_name}-${var.environment}-private-rt-${count.index}" })
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database subnets share the private route tables (still no direct
# internet route, NAT-only outbound if ever needed for patching).
resource "aws_route_table_association" "database" {
  count          = 2
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# --- Security groups ---

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-${var.environment}-eks-nodes-"
  description = "EKS worker nodes"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.project_name}-${var.environment}-eks-nodes-sg" })

  # Node-to-node and control-plane-to-node communication (EKS manages
  # the detailed rules for control plane traffic separately via the
  # cluster security group; this covers intra-VPC pod/node traffic).
  ingress {
    description = "Intra-VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-${var.environment}-db-"
  description = "RDS - only reachable from EKS node subnets on 3306"
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, { Name = "${var.project_name}-${var.environment}-db-sg" })

  ingress {
    description     = "MySQL from EKS nodes only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
