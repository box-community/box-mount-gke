# Security policy

## Scope

This repository is a demonstration, not a production deployment. It handles Box credentials and cloud resources, so use a disposable Box folder and a dedicated Box application when testing.

## Reporting a vulnerability

Please do not open a public issue for a suspected credential exposure or security vulnerability. Report it privately to the repository maintainers using the security contact configured for the published repository.

Immediately revoke any Box key, developer token, service account key, or cloud credential that may have been committed or exposed.

## Credential rules

- Store Box JWT configuration in a secret manager or Kubernetes Secret; never commit it.
- Grant the Box identity access only to the demo content it needs.
- Do not place Box credentials in the container image or in the worker's environment.
- Delete temporary GKE, Artifact Registry, and VM resources when they are no longer needed.
