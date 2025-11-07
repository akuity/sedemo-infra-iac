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