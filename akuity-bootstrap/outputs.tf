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

output "kargo_custom_url" {
  description = "The ID of the Kargo instance"
  value       = local.kargo_custom_url
}

output "argo_custom_url" {
  description = "The ID of the ArgoCD instance"
  value       = local.argo_custom_url

}
