# Contributing

Thanks for helping improve this demo.

## Development guidelines

- Keep the demo focused on Box Mount, Box AI, and a minimal GKE Job.
- Never commit Box JWT files, private keys, developer tokens, kubeconfig files, or cloud credentials.
- Do not add the proprietary Box Mount binary to the repository.
- Use fictional documents for fixtures and examples.
- Update the README and `docs/demo-runbook.md` when changing the setup or demo flow.

## Testing changes

Run the shell syntax checks before opening a pull request:

```bash
bash -n scripts/*.sh
```

An end-to-end test requires Box Mount preview access, a Box folder, Box AI entitlement, and a Google Cloud project. The test should use a disposable folder and fictional documents.
