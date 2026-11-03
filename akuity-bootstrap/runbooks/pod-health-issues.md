## General

- First, do the initial triage and collect the basic information to understand the incident.
- Next, send a Slack notification with the link to the conversation to channel "#incidents" with basic detail.
- Next, work on the incident according to the runbook. Don't take any action automatically, ask for approval.
- If the app is stable, check 30 seconds later again, then you can close the incident automatically. Please do slack all the details in concise messages.
- If you get stuck, send a Slack message again and mention that you need help.
- Please ensure you send Slack message with the link to the conversation, so engineer can work with you together if needed.

## Pod Health Issues (Like Crashes & Probe Failures)

**Symptoms**:

- Pod status shows CrashLoopBackOff with increasing backoff delay and frequent restarts.
- Container terminates shortly after start with Error, OOMKilled, or non-zero exit code.
- Kubelet events show "Liveness probe failed" or "Readiness probe failed" with timeouts or non-200 status codes.
- Pod flaps between Ready/NotReady states; Service endpoints missing or unstable.
- Application logs show continued processing while health probes are failing.
- Health endpoint path/port mismatches or probe target configuration errors.
- Init container failures blocking main container startup.
- Application startup failures due to missing configuration, secrets, or volume mount issues.

**Root cause**:

- Misconfigured health probes: overly aggressive timing (low delays, short timeouts, high failure thresholds) or incorrect targets.
- Missing `startupProbe` for slow-starting applications causing premature liveness/readiness evaluation.
- Resource constraints: insufficient memory limits causing OOM kills, CPU throttling delaying probe responses.
- Configuration issues: invalid command/args, missing environment variables, incorrect ConfigMap/Secret references.
- Infrastructure problems: volume mount failures, init container issues, external dependency unavailability.
- Application defects: startup panics, configuration errors, or incompatible versions.
- Authentication requirements on health endpoints without proper probe configuration.

**Solution**:

- Analyze pod events and container logs to identify specific failure patterns (crashes vs probe timeouts vs configuration errors).
- For probe-related issues:
  - Validate probe configuration: correct `path`, `port`, and `scheme` against container specifications.
  - Add or tune `startupProbe` to delay liveness/readiness checks until application initialization completes.
  - Relax probe timing: increase `initialDelaySeconds`, `timeoutSeconds`, `periodSeconds`, and `failureThreshold` as appropriate.
  - Simplify health checks if authentication or complex headers are required (use TCP probes or unauthenticated endpoints).
- For resource-related crashes:
  - Right-size memory requests/limits based on observed usage to prevent OOM kills.
  - Adjust CPU requests if throttling affects probe response times.
- For configuration issues:
  - Verify container command/args and environment variable correctness.
  - Ensure ConfigMaps/Secrets exist with correct keys and data formats.
  - Confirm volume mounts have proper paths and permissions.
- For init container failures, resolve dependency issues before addressing main container problems.
- After applying fixes, roll the workload to clear backoff state and monitor for stable startup and sustained readiness.