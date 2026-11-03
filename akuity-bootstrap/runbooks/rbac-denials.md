## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## Unauthorized Access / RBAC Denials

**Symptoms**:

- API server returns "Forbidden" or "(rbac) access denied" when a user or pod tries to access a resource.
- Controller/pod logs show errors like "cannot list/get/watch … is forbidden" or webhook reconciliation failures due to missing verbs.
- Events on affected resources indicate authorization failures for the ServiceAccount.

**Root cause**:

- ServiceAccount is not bound to a Role/ClusterRole granting required verbs on the target resources.
- Role/ClusterRole rules use wrong `apiGroups`, `resources`, `resourceNames`, or missing required `verbs`.
- Binding targets the wrong subject (username/group/ServiceAccount) or wrong namespace for namespaced RoleBindings.
- Workload references an unexpected ServiceAccount or defaults to `default` without required permissions.

**Solution**:

- Identify the principal:
  - For pods/workloads, confirm the `spec.serviceAccountName` the workload uses; if empty, it defaults to the `default` ServiceAccount.
  - For user access, capture the username/group info from the failing context and match to bindings.
- Inspect RBAC objects:
  - Review relevant `Role`/`ClusterRole` rules to ensure correct `apiGroups`, `resources`, `verbs`, and optional `resourceNames`.
  - Verify `RoleBinding`/`ClusterRoleBinding` subjects reference the correct ServiceAccount (namespace/name) or user/group.
- Remediate with least privilege:
  - If the workload uses the wrong ServiceAccount, patch the workload to reference the intended ServiceAccount.
  - If permissions are missing, patch or create a namespaced `Role` with only the required verbs/resources and bind it via `RoleBinding` to the ServiceAccount.
  - For cluster-wide needs, bind a minimal `ClusterRole` via `ClusterRoleBinding` to the ServiceAccount; prefer namespace `Role` where possible.
- Validate apiGroups and resource names for CRDs to ensure rules match the installed group/version.
- After changes, roll or refresh the workload so it re-attempts the operation; monitor logs/events to confirm denials stop and desired actions succeed.
