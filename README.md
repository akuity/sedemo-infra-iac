# Akuity IaC Demo Project

This project uses terraform to bootstrap a full GitOps environment from scratch.  
It is primarily intended for use by our field teams to demonstrate these capabilities, but may present a useful example or starting template for customers.

It logically represents the "base" layer often controlled by infrastructure teams, and does not configure individual application manifests.

## Directories
- `core-env` this folder contains 2 modules:
  - `aws` provisions base AWS resources including IAM roles used by the pipeline and operators. and domain used by deployed apps.  Customers will most likely already have solutions for this base layer.
  - `eks-clusters` provisions a VPC and small EKS cluster to host sample applications and Akuity local agents. It installs `ingress-nginx` tied to the demo domain.
- `akuity-bootstrap` requires an existing Akuity Org and API key with admin rights. The terraform module will:
  - provision an AKP instance (Enterprise ArgoCD) with Akuity Intelligence & AI Powered Runbooks enabled
  - provision an Enterprise Kargo instance
  - register the Kargo instance (cluster) to the ArgoCD instance so we can GitOps Kargo config
  - install a self-managed Kargo agent (`sedemo-primary`) in the EKS cluster with access to the ArgoCD instance
  - install Akuity's ArgoCD agent in the EKS cluster
  - create the top-level `app-of-apps` ArgoCD Application pointing to `bootstrap/` in the platform repo
- `argocd-bootstrap` creates ArgoCD projects and seeds the `app-of-apps` configuration pointing to the platform repo.
   - `components` cluster add-ons like prometheus, metrics-server, and external-secrets
   - `apps` the sample applications representing business workloads
   - `secrets` External-Secrets manager `SecretStores` connected to AWS Secrets Manager, used by Kargo


## Related Repos

This repo delegates application definitions to the https://github.com/akuity/sedemo-platform repo where actual `Application` manifest live.