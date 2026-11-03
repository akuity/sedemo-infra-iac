## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## ArgoCD Application Sync Failure

**Symptoms**:

- ArgoCD application shows "Syncing" status for extended period without completing.
- Sync operation fails with errors in ArgoCD UI or application events.
- Application status shows "Failed" or "Error" in sync phase.
- Repeated sync attempts fail with same error message.
- Resources not being created, updated, or deleted as expected during sync.

**Root cause**:

- Invalid or malformed manifests in Git repository preventing sync.
- Insufficient RBAC permissions for ArgoCD to create/update target resources.
- Resource conflicts or dependencies preventing successful application of manifests.
- Git repository access issues (authentication, branch/path not found).
- Target cluster connectivity problems or cluster resource constraints.
- Kubernetes API server rate limiting or timeout issues during large syncs.
- Helm chart or Kustomize rendering failures in application source.

**Solution**:

- Check ArgoCD application status and recent sync attempts to identify specific failure reasons and error messages.
- Review application events using ArgoCD events to understand sync operation timeline and failure points.- Inspect individual managed resources for creation/update failures; check if RBAC permissions allow ArgoCD service account to perform required operations.
- For manifest validation issues, review Git repository content for syntax errors, invalid resource definitions, or missing dependencies.
- Check target cluster health, API server responsiveness, and available resources (CPU, memory, storage) that might prevent resource creation.
- If Helm or Kustomize source, verify template rendering succeeds and produces valid Kubernetes manifests.
- After addressing root cause, trigger manual sync or wait for next automatic sync cycle; monitor for successful completion and resource health.
