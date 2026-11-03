## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## PersistentVolumeClaim Binding Failures

**Symptoms**:

- PVC remains in Pending; events show ProvisioningFailed, FailedBinding, or WaitingForFirstConsumer.
- StorageClass not found or no dynamic provisioner available for requested class.
- AccessModes or requested size incompatible with available PVs.
- Topology constraints prevent binding (zone/region mismatch).
- Pods referencing the PVC stay Pending due to unbound claims.

**Root cause**:

- Incorrect `storageClassName` on the PVC or StorageClass missing/mis-typed.
- Claim selectors (matchLabels/fields) too restrictive; no PV matches.
- Pod uses wrong `claimName` in volumes, or mounts reference a non-existent PVC.
- StorageClass `volumeBindingMode: WaitForFirstConsumer` with pod scheduling constraints that cannot be satisfied in allowed topologies.
- No suitable PVs exist and dynamic provisioning is failing due to parameters, permissions, or topology limits.

**Solution**:

- Review PVC events/details to identify the exact bind/provisioning failure and confirm associated StorageClass and parameters.
- Validate the PVC `storageClassName` exists and matches the intended class; if the claim is unbound and mis-typed, patch it to the correct class.
- Check for PVC `spec.selector` usage; if labels prevent matching any PVs, remove or correct selectors to allow binding to available volumes.
- Ensure Pods reference the correct `claimName` and namespace; if wrong, patch the consuming Deployment/StatefulSet/Pod to the correct PVC name.
- For `WaitForFirstConsumer` cases, confirm pod node selectors/affinity align with StorageClass allowed topologies; relax pod scheduling constraints if they block provisioning.
- If no dynamic provisioner is present for the selected StorageClass or parameters are invalid, surface the issue to cluster owners; creating PVs or changing storage backends is out of scope for automated changes.
- After adjustments, let the controller retry binding/provisioning or roll the workload; monitor until the PVC becomes Bound and pods progress to Running.
