## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## Node / Pod Networking Issues

**Symptoms**:

- Pods cannot reach other pods/Services; DNS lookups fail or time out.
- New pods stuck in `ContainerCreating` with events like `FailedCreatePodSandBox` or `CNI failed to assign IP`.
- Pod IPs missing or duplicate; Services have no Endpoints due to pods not Ready.
- CNI DaemonSet pods (e.g., calico, cilium, flannel, weave) are CrashLooping or NotReady in `kube-system`.
- Nodes report `NetworkUnavailable` or frequent route setup errors in events/logs.

**Root cause**:

- CNI DaemonSet degraded or not scheduled on all nodes (tolerations/nodeSelectors mismatch).
- IPAM exhaustion or conflicting pod CIDRs; CNI cannot allocate addresses.
- MTU or routing misconfiguration in CNI config; kube-proxy/eBPF settings mismatch.
- NetworkPolicies unintentionally blocking inter-pod or DNS traffic.
- kube-dns/CoreDNS issues causing name resolution failures despite network being healthy.

**Solution**:

- Inspect kube-system networking components:
  - Check CNI DaemonSet status (calico/cilium/flannel/weave) and ensure pods run on all nodes.
  - Review CNI pod logs around failure times for IPAM errors, route/MTU issues, or datastore connectivity.
- Verify pod networking state:
  - Confirm affected pods have IPs assigned and are Ready; review events for sandbox/CNI errors.
  - Check Services/Endpoints to ensure endpoints are populated for Ready pods.
- NetworkPolicy review:
  - List and inspect NetworkPolicies in involved namespaces; verify rules allow required ingress/egress (namespaces, selectors, ports), especially DNS (UDP/TCP 53) and service ports.
  - Where appropriate, patch existing policies to permit required traffic while maintaining least privilege.
- CNI DaemonSet remediation (with approval):
  - If DaemonSet is healthy but pods are stale, trigger a safe restart by patching the DaemonSet pod template annotation to force a rollout, or delete specific unhealthy CNI pods to let the DaemonSet recreate them.
  - If DaemonSet fails to schedule on some nodes due to tolerations/selectors, patch them to align with node taints/labels.
- CNI configuration:
  - If CNI uses a ConfigMap/CRD stored in-cluster (e.g., MTU, IP pool ranges) and logs clearly indicate a misconfiguration, propose a minimal patch and apply after validation and approval.
  - IPAM pool exhaustion or routing domain changes beyond in-cluster config should be surfaced to cluster owners.
- DNS components:
  - Check CoreDNS Deployment status and logs; if configuration (ConfigMap) issues are evident, patch and roll the Deployment.
- After changes, recreate or roll affected workloads, then validate pod-to-pod and pod-to-service connectivity and DNS resolution; continue to monitor events/logs.
