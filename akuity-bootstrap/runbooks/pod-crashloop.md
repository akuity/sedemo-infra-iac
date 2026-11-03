## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a slack notification with the link to the conversation to channel "incidents" with basic detail.
- Next, work on the incident according to the runbook. Propose every change and wait for human approval before applying it. Never apply a change without approval.
- Apply approved fixes by patching the live Kubernetes resource only. Do not commit to Git, open pull requests, sync the Argo CD application, or promote with Kargo.
- After applying a fix, wait 60 seconds and check again. Close the incident only if the application is Healthy and the pod's restart count has not increased during that time. A Progressing status is not stable.
- Before proposing a further change, check that the live resource still contains your last patch. If it does not, report that the change was reverted (for example by an Argo CD sync) instead of escalating.
- If you are stuck, send a slack message again and mention that you need help.
- Please ensure you send slack messages with the link to the conversation, so an engineer can work with you if needed. Keep all slack messages concise.

## CrashLoopBackOff caused by failing probes

**Symptoms**:
- Pod is in `CrashLoopBackOff` with a high restart count, and the container is never Ready.
- Pod events show `Liveness probe failed` / `Readiness probe failed` (for example `connection refused`), followed by `Killing` / `Container ... failed liveness probe, will be restarted`.
- The application logs show a normal startup with no application error before each restart.
- Deployment status "Degraded", "exceeded its progress deadline".

**Root cause**: The liveness and readiness probes check a port (or path) the application is not serving, so the kubelet kills a healthy process and the pod never becomes Ready.

**Solution**:

* Compare the probe `port` and `path` with the port the application actually listens on: check the container `args`/`command` (for example `--port=...`), `containerPort`, and the startup log line.
* Propose a patch that points both the liveness and readiness probes at the port the application listens on, and apply it after approval. Change nothing else.
* In the incident summary, state the mismatch you found (probe port vs. listening port) and note that the change was made only on the live resource, so the Deployment will show OutOfSync in Argo CD until the permanent fix lands in Git.

## Other CrashLoopBackOff causes

If the probes match the listening port, do not change them. Use the container's last termination reason and logs to identify the cause (for example `OOMKilled`, a non-zero exit with an application error, or a missing ConfigMap/Secret), report your findings, and ask for help instead of guessing a fix.
