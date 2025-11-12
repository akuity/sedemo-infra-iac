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
  - register the Kargo instance (cluster) to the ArgoCD instance so we can GitOps kargo config
  - Install a Kargo agent with access to the above ArgoCD instance so it can notify and monitor ArgoCD progress
  - install Akuity's ArgoCD agent in the EKS cluster from above
  - Install Akuity's Kargo agent in the EKS cluster from above
- `argocd-bootstrap` creates a handful of 'projects' and seeds them with app-of-app configuration pointint to platform team repos.
   - `components` cluster add-ons like prometheus, metrics-server, and external-secrets
   - `apps` the sample application representing business workloads
   - `kargo` the project and workflow definitions for Kargo
   - `secrets` External-Secrets manager `SecretStores` connected to AWS Secrets Manager, used by Kargo


## Related Repos

This repo delegates application definitions to the https://github.com/akuity/sedemo-platform repo where actual `Application` manifest live.