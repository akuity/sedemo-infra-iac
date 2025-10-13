# Argo Demo for Akuity Platform - IaC Repo

This repo contains the Infrastructure-as-Code needed to bootstrap your Akuity Platform.

The repo is intended to represent that area of responsbility typically owned by core infrastructure teams.

## Scope

- Provision Core Network
- Provision Domains
- Provision Argo/Kargo k8s cluster (optional, default us Akuity hosted)
- Provision Runtime K8s cluster(s)
- Bootstrap Akuity 
 - ArgoCD App-of-Apps


## Tools

This repo uses terraform modules that can be applied with Hashicorp or OpenTofu clients.


## Prereqs

- `AKUITY_API_KEY_ID` envar, from Akuity org.
- `AKUITY_API_KEY_SECRET` 
- `AKUITY_SERVER_URL` if using self-hosted


## Running



## TODO

- [ ] Apply app-of-apps
- [ ] Configure OIDC for argo
- [ ]  ... kargo
- [ ] provision demo k8s cluster in AWS EKS
- [ ] Demo domainname
