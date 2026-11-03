## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a slack notification with the link to the conversation to channel "incidents" with basic detail.
- Next, work on the incident according to the runbook. Propose every change and wait for human approval before applying it. Never apply a change without approval.
- Apply approved fixes by patching the live Kubernetes resource only. Do not commit to Git, open pull requests, sync the Argo CD application, or promote with Kargo.
- After applying a fix, wait 60 seconds and check again. Close the incident only if the application is Healthy and the pod's restart count has not increased during that time. A Progressing status is not stable. If the pod restarted again, propose the next step of the runbook.
- If you are stuck, send a slack message again and mention that you need help.
- Please ensure you send slack messages with the link to the conversation, so an engineer can work with you if needed. Keep all slack messages concise.

## Out of memory

**Symptoms**: Pod unexpectedly dies with `OOMKilled` status, usually followed by `CrashLoopBackOff`.

**Root cause**: The pod is consuming more memory than its memory limit.

**Solution**:

* Propose a temporary increase to the memory limit of the container, and apply it after approval.
* Increase the memory limit (and the request to the same value) in 50Mi increments until the pod is stable.
* In the incident summary, note that the change was made only on the live resource, so the Deployment will show OutOfSync in Argo CD until the permanent fix lands in Git.
