## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## ArgoCD Application Health Degraded

**Symptoms**:

- ArgoCD application shows "Degraded" health status with red indicators in UI.
- Some managed resources report unhealthy status while others remain healthy.
- Application tree view shows failing resources with specific health check failures.
- Application may be "Synced" but health checks indicate runtime problems.
- Resource-specific health messages indicate probe failures, dependency issues, or resource constraints.

**Root cause**:

- Underlying Kubernetes resources failing health checks (readiness/liveness probes, job failures).
- Resource dependency issues where services depend on unhealthy upstream components.
- Resource configuration problems discovered only at runtime (wrong environment variables, missing secrets).
- External service dependencies unavailable causing application components to fail health checks.
- Resource limits too restrictive causing OOM kills or CPU throttling affecting health.
- Network policies or service mesh configuration blocking inter-service communication.

**Solution**:

- Use ArgoCD application tree to identify which specific resources are reporting degraded health and their failure reasons.
- Investigate unhealthy resources by examining their events, logs, and current status to understand root cause of health failures.
- For probe failures, validate readiness/liveness/startup probe configuration against application startup behavior and adjust if too aggressive.
- Check resource requests/limits if health issues correlate with OOM kills or resource pressure; right-size based on observed usage.
- Verify service dependencies are healthy; check DNS resolution, network connectivity, and external service availability.
- Review configuration (ConfigMaps, Secrets, environment variables) for recent changes that might cause runtime failures.
- For services failing due to inter-service communication, check NetworkPolicies, service mesh configuration, and service discovery.
- After resolving underlying issues, monitor ArgoCD application health until all resources report healthy status and application shows overall healthy state.
