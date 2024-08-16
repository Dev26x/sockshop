provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "sock-shop"
  cidr = "10.123.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.123.3.0/24", "10.123.4.0/24"]
  public_subnets  = ["10.123.1.0/24", "10.123.2.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = "sock-shop"
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    goody_node_1 = {
      min_size     = 1
      max_size     = 4
      desired_size = 1

      instance_types = ["t3.medium"]
    }
    goody_node_2 = {
      min_size     = 1
      max_size     = 4
      desired_size = 1

      instance_types = ["t3.medium"]
    }
  }

}

