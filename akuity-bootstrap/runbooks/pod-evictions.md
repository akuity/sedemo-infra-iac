## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## High Pod Eviction Rate

**Symptoms**:

- Frequent Pod evictions with node conditions like MemoryPressure or DiskPressure.
- Container restarts with OOMKilled in last terminated state.
- Events indicate ephemeral-storage usage exceeded or eviction manager thresholds triggered.
- Nodes show pressure conditions; workloads repeatedly rescheduled across nodes.

**Root cause**:

- Memory requests/limits too low or unbounded usage causing OOMKilled and subsequent evictions.
- Excessive ephemeral storage usage (logs, caches, temp files) without requests/limits.
- Large emptyDir volumes without size constraints; log growth or data accumulation.
- Node-level resource scarcity leading to evictions of lower-priority pods.

**Solution**:

- Review recent Pod events and termination reasons to confirm eviction cause (MemoryPressure, DiskPressure, OOMKilled, ephemeral-storage).
- For OOMKilled:
  - Right-size `resources.requests/limits.memory` based on observed needs; avoid limits so low that the kernel OOMs the process.
  - If CPU starvation affects stability, consider appropriate CPU requests as well.
- For DiskPressure/ephemeral storage:
  - Add/adjust `resources.{requests,limits}.ephemeral-storage` for containers to bound usage predictably.
  - Constrain or manage temporary data: set `emptyDir.sizeLimit` where applicable; rotate/reduce in-container logs if they drive growth.
  - Where persistent data is required, prefer PersistentVolume over `emptyDir` to avoid eviction from node storage pressure.
- Use Pod priority judiciously so critical workloads are less likely to be evicted under pressure.
- After applying changes, roll the workload to pick up updates; monitor events and restarts to ensure evictions cease and pods remain Ready.
- If node pressure persists cluster-wide, surface the capacity bottleneck to owners; infrastructure/node scaling is out of scope for automated changes.
