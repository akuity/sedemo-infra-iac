## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## Service Connectivity Issues

**Symptoms**:

- Pods cannot reach a Service (timeouts, connection refused, or HTTP 503).
- Service has no endpoints or endpoints point to unexpected pods.
- DNS name resolves but traffic still fails, or DNS name cannot be resolved.
- NetworkPolicies present in source or destination namespaces limiting traffic.

**Root cause**:

- Service selectors do not match Pod labels, producing no/endpoints for the wrong pods.
- Service ports/targetPorts mismatch actual container ports or named ports.
- Protocol mismatch (TCP vs UDP) or headless/ClusterIP misconfiguration.
- Pods not Ready, so Endpoints/EndpointSlices exclude them.
- NetworkPolicies block ingress/egress between client and server pods or across namespaces.
- Cross-namespace reference uses wrong DNS form or labels used in NetworkPolicies don’t select intended peers.

**Solution**:

- Validate Service selectors vs Pod labels; align them so the Service selects the intended pods. If incorrect, patch either the Service selector or Pod labels.
- Inspect Endpoints/EndpointSlices to confirm the Service backs the expected Pod IPs and ports; address any gaps by fixing selectors or pod readiness.
- Check Service `ports` and `targetPort` definitions against container port numbers/names; correct mismatches (including protocol TCP/UDP).
- Confirm pods are Ready (conditions and readiness probes). If probes are too strict, adjust thresholds/delays to allow endpoints to populate.
- Review NetworkPolicies in both source and destination namespaces; ensure rules allow the required ingress/egress (namespaces, pod selectors, ports). Where appropriate, patch policies to explicitly permit needed traffic.
- For cross-namespace access, verify namespace labels used by NetworkPolicies and the DNS name form used by clients; align labels/selectors if they prevent intended communication.
- After applying changes, wait for endpoints to update or roll the workload if necessary; re-test connectivity and monitor for stable success.
