## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## Cluster Time Drift

**Symptoms**:

- Logs across pods show inconsistent timestamps for the same events; distributed systems report clock skew.
- TLS errors like "certificate has expired or not yet valid" or token validation failures appear sporadically.
- Controllers emit reconciliation jitter or event timestamps out of order.
- Time-sync DaemonSet pods (e.g., chrony/ntp) log large offset corrections or repeated sync failures.

**Root cause**:

- Node time synchronization service not running or misconfigured; unreachable NTP servers.
- Time-sync DaemonSet not deployed, failing, or lacking permissions to adjust time.
- Host/VM hypervisor time drift affecting node clocks; leap second/offset handling issues.

**Solution**:

- Inspect Node objects and recent events for skew-related warnings and confirm which nodes are affected.
- If a time-sync DaemonSet exists (e.g., chrony/ntp/time-sync):
  - Check DaemonSet status to ensure pods are running on all nodes.
  - Review DaemonSet pod logs for large offsets, no server reachable, or auth failures.
  - If misconfigured via ConfigMap/Env, patch the Kubernetes resource (ConfigMap/DaemonSet) with corrected settings and trigger a rollout.
- If no time-sync DaemonSet is present or node-level services are unhealthy, surface the issue to cluster owners; modifying host time services is out of scope for automated changes.
- After remediation, roll or restart affected workloads that rely on time-sensitive tokens or sessions to ensure clean state.
- Monitor logs for stable timestamps and absence of TLS/time validation errors; re-check DaemonSet status.
