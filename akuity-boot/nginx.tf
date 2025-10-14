resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

#   set = [
#     {
#       name  = "controller.service.externalTrafficPolicy"
#       value = "Local"
#     }
#   ]
}