# akuity-bootstrap

Terraform module that provisions and configures all Akuity Platform resources for the SE demo environment. Run this after `core-env/aws` has created the EKS cluster and Route53 zone.

## What It Creates

| Resource | Details |
|----------|---------|
| Argo CD instance (AKP) | Custom FQDN, Microsoft OIDC via Dex, Rollouts extension, Akuity Intelligence with OOM runbook, declarative management enabled |
| Kargo instance | Custom FQDN, Microsoft OIDC via Dex, admin account enabled, 20-item freight/promotion retention |
| Kargo agent `sedemo-managed` | Cloud-managed agent; linked to the AKP Argo CD instance |
| Kargo agent `sedemo-primary` | Self-hosted local agent; configured to use `kargo-secrets-namespace` for global credentials |
| Default shard | Points to `sedemo-primary` |
| EKS cluster (ArgoCD) | Primary EKS cluster registered with Argo CD using `aws eks get-token` exec credential |
| Kargo cluster (ArgoCD) | Kargo instance registered as a cluster in Argo CD for declarative project management |
| Route53 records | CNAME for Argo CD and Kargo custom domains pointing to Akuity cloud endpoints |

## RBAC

- `sedemo-admin` group → `role:platform-team` (full access)
- `sedemo-auditor` group → `role:readonly`
- `github-actions` service account → can refresh applications and applicationsets

## Variables

See `variables.tf` for the full list. Key inputs:

| Variable | Description |
|----------|-------------|
| `MS_OAUTH_CLIENT_ID` | Azure AD app client ID for Microsoft OIDC |
| `MS_OAUTH_CLIENT_SECRET` | Azure AD app client secret |
| `MS_OAUTH_TENANT_ID` | Azure AD tenant ID |
| `argo_admin_password` | Initial admin password (bcrypt-hashed at apply time) |
| `akp_instance_name` | Name of the Argo CD instance |
| `kargo_instance_name` | Name of the Kargo instance |

## Usage

```bash
# Authenticate to AWS (see core-env/aws/README.md)
aws sso login --profile sedemo

# Apply
terraform init
terraform apply
```

Remote state from `core-env/aws` is loaded automatically via `data.tf`.

## TODOs

- [ ] Use OIDC to authenticate to AKP org instead of static API keys
- [ ] Use a system/service account instead of a personal PAT for GitHub writes
