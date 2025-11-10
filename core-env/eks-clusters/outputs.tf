output "primary_cluster_name" {
  value = module.eks.cluster_name
}
output "primary_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "primary_cluster_ca" {
  value = module.eks.cluster_certificate_authority_data
}
output "demo_domain" {
  value = var.root_domain_name
}

output "root_zone_id" {
  value = data.aws_route53_zone.root_demo_domain_zone.id
}

output "irsa_role_arn" {
  # needed by SA setup by platform team
  value = module.eks.eks_managed_node_groups.default.iam_role_arn
}

output "secrets_sa_role" {
  value = aws_iam_role.eks_service_account_role.arn
}