## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## Pending Pods due to Scheduling / Resource Constraints

**Symptoms**:

- Pod remains in Pending state; scheduler reports Unschedulable.
- Events mention insufficient resources (CPU, memory, GPU, ephemeral storage) on all nodes.
- Messages indicate taint/toleration mismatch preventing placement on eligible nodes.
- Node selector, node affinity/anti-affinity, or topology spread constraints reduce eligible nodes to zero.
- IP address exhaustion or maxPods per node limit reached; networking capacity prevents scheduling.
- Cluster autoscaler not triggering or capped; no new nodes added to satisfy requests.

**Root cause**:

- Resource requests too large for available nodes; limits/requests mismatched to workload needs.
- Missing or incorrect tolerations for tainted nodes.
- Overly strict selectors/affinity/anti-affinity or topology spread policies that eliminate candidates.
- Node pool capacity exhausted (CPU/memory/GPU/IPs) or maxPods per node reached.
- Cluster autoscaler disabled/misconfigured (min/max bounds, scale-down delay, resource limits) or constrained by policies/quotas.
- Namespace ResourceQuota or LimitRange preventing requested resources from being admitted.

**Solution**:

- Review pod scheduling events and messages to pinpoint the exact Unschedulable reason and failing predicates.
- Validate and right-size resource requests/limits to realistic needs; reduce temporarily if appropriate to fit available capacity.
- Align taints/tolerations so the pod can land on intended nodes; remove unnecessary taints where acceptable.
- Relax or correct node selectors, affinity/anti-affinity, and topology spread rules to increase the eligible node set.
- Surface cluster-level capacity bottlenecks (e.g., node pool exhaustion, IP/maxPods limits) and notify owners; cluster or cloud scaling actions are out of scope for automated changes.
- Use pod priority and preemption policies judiciously to prioritize critical workloads when resources are scarce.
- After applying changes, allow the scheduler to re-evaluate or roll the workload; monitor until pods progress to Running and Ready.
