data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "socksShop-eks"
}

# VPC Module Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "socks-shop-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/socksShop-eks" = "shared"
    "kubernetes.io/role/elb"              = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/socksShop-eks" = "shared"
    "kubernetes.io/role/internal-elb"     = 1
  }
}

# KMS Key Resource
resource "aws_kms_key" "this" {
  description             = "KMS key for EKS cluster"
  deletion_window_in_days = 10
}

# Conditional creation of KMS Alias
resource "aws_kms_alias" "this" {
  count = var.create_alias ? 1 : 0

  name          = "alias/${var.kms_alias_name}"
  target_key_id = aws_kms_key.this.id
}

variable "create_alias" {
  description = "Whether to create the KMS alias"
  default     = true
}

variable "kms_alias_name" {
  description = "Name of the KMS alias"
  default     = "eks/socksShop-eks"
}

# Conditional creation of CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = 90
}

variable "create_log_group" {
  description = "Whether to create the CloudWatch Log Group"
  default     = true
}

# EKS Module Configuration
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.cluster_name
  cluster_version = "1.27"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type                    = "AL2_x86_64"
    associate_public_ip_address = true
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}
