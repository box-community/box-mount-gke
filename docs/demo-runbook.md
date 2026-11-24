# Presenter runbook

> **Demo only.** Do not use this runbook as a production deployment guide. Use fictional candidate data, a disposable Box folder, and a disposable Google Cloud project.

## Story

“A recruiter places a job offer and candidate CV into a Box folder. A short-lived GKE worker mounts that Box folder, uses Box AI to compare the two documents without downloading their contents, and writes a cited review report back to Box.”

## Demo sequence

1. Show the Box folder:

   ```text
   Incoming/platform-engineer/
     job-offer.md
     candidate-cv.md
   Reviewed/
   ```

2. Show the GKE node and the `box-demo` namespace.
3. Run one Job:

   ```bash
   ./scripts/run-job.sh
   ```

4. Point out the log line showing the report path.
5. Refresh Box and open `Reviewed/platform-engineer-candidate-review.md`.
6. Highlight the Box file IDs and citations in the report.
7. Explain that the Job is ephemeral and the node pool can be scaled back to zero.

## What each component demonstrates

| Component | Demo point |
|---|---|
| Box | Content ownership, permissions, source documents, and final report |
| Box Mount | POSIX access to Box from the workload and two-way sync |
| GKE | Scheduling, secrets, and one-shot execution |
| Box AI | Server-side comparison of multiple Box files with citations |
| Cloud Build | Container build without Docker on the presenter’s laptop |

## What not to claim

- This repository is not production-ready and does not provide a production security baseline or SLA.
- The result is not an automated hiring decision.
- The demo does not infer protected characteristics.
- The base path does not yet use Agent Substrate or Filestore Agent Volumes.
- The Box Mount binary is a developer-preview dependency and is intentionally not included in this repository.

## Failure map

| Symptom | Likely cause |
|---|---|
| `pip: command not found` on VM | Expected; dependencies install inside Cloud Build image |
| `Init:Error` | Secret key/path mismatch or runtime directory ownership |
| `PermissionError` for JWT | The runtime JWT file or parent directory is not owned by `boxmount` |
| `No case folders found` | `Incoming` is empty or role folders have not synced into Box Mount |
| `Box folder not found for case` | Local role folder name differs from the Box folder name |
| Box AI HTTP 403 | Box AI entitlement, app authorization, or acting identity issue |
| `kubectl` credential errors | Refresh gcloud authentication and recreate cluster credentials |
| Node remains running | Wait for the resize operation before retrying another resize |
