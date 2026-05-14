# Akuity IaC Demo Project

This project uses terraform to bootstrap a full GitOps environment from scratch.  
It is primarily intended for use by our field teams to demonstrate these capabilities, but may present a useful example or starting template for customers.

It logically represents the "base" layer often controlled by infrastructure teams, and does not configure individual application manifests.

## Directories
- `core-env` this folder contains 2 modules:
  - `aws` provisions base AWS resources including IAM roles used by the pipeline and operators. and domain used by deployed apps.  Customers will most likely already have solutions for this base layer.
  - `eks-clusters` provisions a VPC and small EKS cluster to host sample applications and Akuity local agents. It installs `ingress-nginx` tied to the demo domain.
- `akuity-bootstrap` requires an existing Akuity Org and API key with admin rights. See [`akuity-bootstrap/README.md`](akuity-bootstrap/README.md) for full details. The terraform module will:
  - provision an AKP instance (Enterprise ArgoCD) with Akuity Intelligence & AI Powered Runbooks enabled
  - provision an Enterprise Kargo instance with Microsoft OIDC
  - register the Kargo instance (cluster) to the ArgoCD instance so we can GitOps Kargo config
  - install a self-managed Kargo agent (`sedemo-primary`) in the EKS cluster with access to the ArgoCD instance
  - install Akuity's cloud-managed ArgoCD agent (`sedemo-managed`) in the EKS cluster
  - create Route53 DNS records for both the ArgoCD and Kargo custom domains
- `argocd-bootstrap` requires ArgoCD to already be running (deployed by `akuity-bootstrap`). The terraform module will:
  - create ArgoCD projects (`components`, `apps`, `templated-apps`, `akuity-lab`, etc.)
  - seed the root `app-of-apps` ArgoCD Application pointing to `bootstrap/` in the platform repo
  - seed the `app-of-components` Application pointing to `components/declarations/` in the platform repo
  - seed the `templated-apps` Application pointing to `templated-teams/` in the platform repo
  - after apply, ArgoCD takes over and all subsequent app/component management is fully declarative from the platform repo


## Related Repos

This repo delegates application definitions to the https://github.com/akuity/sedemo-platform repo where actual `Application` manifest live.