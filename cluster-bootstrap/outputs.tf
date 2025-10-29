output "argo_server_url" {
  description = "The URL of the ArgoCD server"
  # TODO: must be someway to get root domain and not assume akuity.cloud
  value = "${akp_instance.se-demo-iac.argocd.spec.instance_spec.subdomain}.cd.akuity.cloud"
}

output "kargo_instance_id" {
  description = "The ID of the Kargo instance"
  value       = akp_kargo_instance.kargo-instance.id
}

output "argo_instance_id" {
  description = "The ID of the ArgoCD instance"
  value       = akp_instance.se-demo-iac.id

}

output "argo_admin_password" {
  description = "The password for the ArgoCD admin user."
  value       = var.argo_admin_password
  sensitive   = true
}

output "iac_cluster_name" {
  description = "The name of the local cluster registered with ArgoCD."
  value       = var.iac_cluster_name
}