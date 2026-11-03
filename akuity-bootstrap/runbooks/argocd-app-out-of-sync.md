## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "PLEASE REPLACE" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## ArgoCD Application OutOfSync Status

**Symptoms**:

- ArgoCD application displays "OutOfSync" status indicating drift from desired state.
- Live cluster resources differ from Git repository manifests.
- Resources show yellow/orange indicators in ArgoCD UI with diff details.
- Application health may be "Healthy" but sync status shows configuration drift.
- Manual changes detected on cluster resources not reflected in Git.

**Root cause**:

- Manual modifications made directly to cluster resources bypassing GitOps workflow.
- External controllers or operators modifying resources (HPA, VPA, admission controllers).
- Resource annotations or labels added by cluster components or monitoring tools.
- Incomplete or failed previous sync operations leaving resources in intermediate state.
- Git repository updated but automatic sync disabled or sync policy not triggered.
- Resource finalizers or webhooks preventing proper updates during sync.

**Solution**:

- Examine OutOfSync resources by checking ArgoCD managed resource diff to understand specific differences between desired and live state.
- Determine if drift is intentional (external controller changes) or unintended (manual modifications).
- For unintended changes, evaluate whether to sync from Git (restore desired state) or update Git to match current live state.
- Check if external controllers are legitimately managing certain fields; consider ignore differences configuration for expected drift.
- Review application sync policy settings; enable auto-sync if desired, or trigger manual sync to restore desired state.
- For resources stuck due to finalizers or webhooks, investigate blocking conditions and resolve dependencies.
- After decision, either sync application to restore Git state or update Git repository to match live changes, then verify application returns to Synced status.
