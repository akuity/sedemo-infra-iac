## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## Image Pull Failure

**Symptoms**:

- Pod status shows ErrImagePull or ImagePullBackOff; repeated back-off events.
- Events indicate registry authentication required/denied, manifest unknown, not found, name unknown, or TLS errors.
- Image tag or digest cannot be resolved; 404 or 401 from registry.
- imagePullSecret not found, wrong reference, or unauthorized scope.
- Network/DNS issues from nodes to registry host; timeouts or name resolution failures.

**Root cause**:

- Incorrect image reference (registry/repo/name, tag, or digest) or image doesn’t exist.
- Missing/invalid imagePullSecrets; expired credentials, wrong namespace, or not attached to ServiceAccount.
- Registry permissions insufficient (no pull scope) or private repo access misconfigured.
- Network egress restrictions, proxy requirements, VPC endpoints, or DNS issues blocking registry access.
- TLS/certificate trust problems with private/insecure registries; node clock skew causing TLS validation failures.
- Rate limiting (e.g., Docker Hub) or throttling by registry.
- imagePullPolicy prevents re-pull when needed and image isn’t cached on node.

**Solution**:

- Inspect pod events to get the exact error (auth denied, not found, TLS, timeout) and confirm failure type.
- Validate the image reference (registry, repository, tag or digest). Prefer pinning by digest for immutability.
- Check that imagePullSecrets exist in the namespace and are correctly referenced by the Pod spec or its ServiceAccount; if missing, add the reference via patch. If credentials are expired and you provide updated tokens, rotate the existing Secret data.
- Review in-cluster NetworkPolicy and core resources (e.g., ServiceAccount, Secret references) that could block registry access; surface any misconfigurations. External permission checks against the registry are out of scope.
- Optionally patch imagePullPolicy to Always during rollout to force a fresh pull when tags are updated.
- To retry the pull after remediation, delete the failing Pod (owned by a controller) or roll the workload so a new Pod is created and pulls the image again.
