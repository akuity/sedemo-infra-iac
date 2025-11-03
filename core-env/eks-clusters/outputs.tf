output "primary_cluster_name" {
    value = module.eks.cluster_name
}
output "primary_cluster_endpoint" {
    value = module.eks.cluster_endpoint
}
output "primary_cluster_ca" {
    value = module.eks.cluster_certificate_authority_data
}