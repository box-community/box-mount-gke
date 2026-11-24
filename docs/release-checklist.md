# Open-source release checklist

Before publishing this repository:

- [ ] Choose and add an approved open-source license.
- [ ] Replace `<OWNER>` in the README with the final repository URL.
- [ ] Confirm that no Box JWT JSON, private key, token, kubeconfig, or cloud credential is present.
- [ ] Confirm that `image/box-mount` is absent. The binary is provided separately to Box Mount preview participants.
- [ ] Run `bash -n scripts/*.sh`.
- [ ] Test the documented flow with a disposable Box folder and fictional documents.
- [ ] Confirm that Box AI is enabled for the acting Box identity.
- [ ] Review the Box Mount preview terms and usage limits before publishing deployment claims.
- [ ] Add the repository license, issue tracker, and security contact.

This repository contains the demo implementation and fixtures. It does not contain a blog post, the Box Mount binary, or Box credentials.
