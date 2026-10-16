# Akuity IaC Demo Project

This project uses terraform to bootstrap a full GitOps environment from scratch.
It is primarily intended for use by our field teams to demonstrate these capabilities, but may present a useful example or starting template for customers.

It logically represents the "base" layer often controlled by infrastructure teams, and does not configure individual application manifests.

## Tooling: OpenTofu, not Terraform

These modules must be run with [OpenTofu](https://opentofu.org/) (`tofu`) version 1.8 or later, which is also what CI uses (`opentofu/setup-opentofu`). HashiCorp Terraform (`terraform`) will not work.

`core-env/eks-clusters` and `akuity-bootstrap` build their S3 backend `key` from input variables, for example:

```hcl
key = "cluster-${var.primary_cluster_name}/terraform.tfstate"
```

OpenTofu 1.8 and later evaluate static variables and locals early, so they work in `backend` blocks. Terraform does not, and `terraform init` fails with:

```text
Error: Variables not allowed
  on providers.tf line 13, in terraform:
  13:     key          = "cluster-${var.primary_cluster_name}/terraform.tfstate"
Variables may not be used here.
```

If you hit this error, run `tofu init` instead (check any `tf` shell alias too). Stick with `tofu` for these states, and don't alternate between `terraform` and `tofu` on the same state file.

## Directories

- `core-env` this folder contains 2 modules:
  - `aws` provisions base AWS resources including IAM roles used by the pipeline and operators. and domain used by deployed apps.  Customers will most likely already have solutions for this base layer.
  - `eks-clusters` provisions a VPC and small EKS cluster to host sample applications and Akuity local agents, plus the IAM roles its in-cluster components use (External Secrets, external-dns). It only uses AWS APIs and never talks to the cluster. `ingress-nginx`, the Twingate connector and external-dns are deployed by Argo CD from [sedemo-platform](https://github.com/akuity/sedemo-platform) (`components/declarations/ingress/`).
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

## Private EKS API and Twingate

The `sedemo-primary` API endpoint is private (`eks_endpoint_public_access = false`). People reach it through Twingate:

- The connector runs in the cluster. Argo CD deploys it from sedemo-platform, with tokens from Secrets Manager (`sedemo/twingate`) via External Secrets.
- Twingate has a Resource for the endpoint hostname (TCP 443). It is managed in the Twingate admin console, not in Terraform.

To use `kubectl`, connect the Twingate client with an account that has access to that Resource.

CI doesn't need Twingate. `core-env/eks-clusters` only calls AWS APIs. `akuity-bootstrap` only touches the cluster when `akp_cluster` is first created, to install the agent, and that happens during the bootstrap window below. `argocd-bootstrap` only talks to the Argo CD API.

### Bootstrapping a fresh cluster

A new cluster's API is only reachable through Twingate once Argo CD has synced the connector, and Argo CD can only sync it after `akuity-bootstrap` has installed the agent through the API. Open the public endpoint for the bootstrap, then close it (the same pattern as `akuityio/infra-terraform`):

1. In a PR, set the `eks_endpoint_public_access` default to `true` in `core-env/eks-clusters/variables.tf`, and merge it to create the cluster. When applying locally, pass `-var eks_endpoint_public_access=true` instead.
2. Apply `akuity-bootstrap` (registers the cluster and installs the agent) and `argocd-bootstrap` (`akuity-iac-main`). If the External Secrets IRSA role ARN changed, update `secrets/irsa-serviceaccount.yaml` in sedemo-platform. The external-dns role name is stable.
3. In Argo CD, sync `app-of-components` and the component apps: `external-secrets`, `eso-secret-store-kargo`, `twingate-connector`, `ingress-nginx`, `external-dns`.
4. Update the Twingate Resource address to the new endpoint hostname (`tofu output primary_cluster_endpoint`, without `https://`). The hostname embeds the cluster ID, so it changes on every recreate.
5. Check that the connector shows as connected in the Twingate admin console, that `kubectl get ns` works over Twingate, and that `akpdemoapps.link` resolves to the new ingress ELB.
6. Revert the default to `false` in a PR and merge. Changing endpoint access takes several minutes.

## Related Repos

This repo delegates application definitions to the https://github.com/akuity/sedemo-platform repo where actual `Application` manifest live.
