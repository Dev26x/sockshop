output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnets" {
  value = module.vpc.private_subnets
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  value = module.eks.node_security_group_id
}

output "region" {
  value = var.region
}

output "cluster_name" {
  value = local.cluster_name
}
