# Box Mount + GKE + Box AI CV review demo

> **Demonstration only — not production-ready.** This repository is an educational proof of concept for Box Mount, Box AI, and GKE. It is not a production application, security baseline, supported deployment, or hiring decision system. Use fictional documents and disposable cloud resources when testing. See [DISCLAIMER.md](DISCLAIMER.md).

This repository is a small, cloud-first demonstration of:

```text
Box files → Box Mount → one-shot GKE Job → Box AI → Box Mount → Box report
```

The Job discovers role folders through the mounted filesystem, resolves the corresponding Box file IDs with the Box SDK, asks Box AI to compare the job offer and CV, and writes a cited Markdown report back to `Reviewed/`. The source documents are passed to Box AI by ID; the worker does not download their bodies.

The base demo does not require Docker locally, Agent Substrate, or Filestore. The repository leaves those as follow-on options so the first demo is easy to run and easy to scale down.

## Repository layout

```text
image/agent.py             Box AI worker
image/Dockerfile           Runtime image with Box Mount and Box SDK
image/entrypoint.sh        Starts Box Mount, runs the worker, unmounts
cloudbuild.yaml            Remote image build configuration
k8s/job.yaml.tmpl          Credential-free Job template
scripts/                   Setup, build, run, verify, and cost controls
fixtures/Incoming/         Fictional demo offers and CVs
docs/demo-runbook.md       Presenter-oriented walkthrough
```

The `box-mount` executable is intentionally not included. Download the compatible Linux binary from the [Box Mount documentation](https://developer.box.com/guides/box-mount) and place it at `image/box-mount` before building. Do not commit it or any Box JWT file.

## Prerequisites

- A Box Platform app using JWT authentication, authorized for the Box enterprise.
- Box AI enabled for the account/enterprise and available to the acting Box identity.
- A Box folder containing an `Incoming` folder. The configured JWT identity must be able to read the source files and write `Reviewed`.
- A GCP project with Artifact Registry, Cloud Build, Compute Engine, and GKE enabled.
- `gcloud`, `kubectl`, `envsubst`, and the GKE auth plugin. Cloud Shell is sufficient; Docker is not required locally.

The Box AI worker uses the official Box Python SDK v10 with JWT extras. Folder listing and the AI request both use generated SDK methods; the worker does not contain a handwritten Box AI HTTP client. The SDK reads the JWT config only inside the container; credentials are not placed in the image.

## 1. Clone and configure

Clone this repository on Cloud Shell or another authenticated Google Cloud environment:

```bash
git clone https://github.com/<OWNER>/box-mount-gke-box-ai-demo.git
cd box-mount-gke-box-ai-demo
```

Set the environment for the existing demo, or replace the values for another project:

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export ZONE="us-central1-a"
export CLUSTER="box-mount-demo"
export NODE_POOL="default-pool"
export BOX_ROOT_FOLDER_ID="your-box-folder-id"
export JWT_FILE="/secure/path/to/box-jwt-config.json"
export BOX_JWT_SECRET_KEY="$(basename "$JWT_FILE")"
```

The JWT filename is significant: it must match the key stored in the Kubernetes Secret. The setup script preserves that filename.

## 2. Put Box Mount in the image directory

Copy the Linux x86_64 Box Mount binary into the repository:

```bash
cp /path/to/box-mount image/box-mount
chmod 0755 image/box-mount
./image/box-mount --version
```

Use the binary that matches the architecture of the GKE nodes. Use `linux-x86_64` for x86 nodes and `linux-aarch64` for ARM nodes.

## 3. Prepare GKE and the Box Secret

```bash
./scripts/prepare-cluster.sh
```

This creates the `box-demo` namespace and creates or updates the `box-mount-jwt` Secret. The script never prints the Secret contents.

## 4. Upload the synthetic demo documents to Box

Ensure Box Mount is running on the admin VM and the root folder is mounted at `/mnt/box`. Then run from the repository root:

```bash
mkdir -p /mnt/box/Incoming /mnt/box/Reviewed
cp -R fixtures/Incoming/* /mnt/box/Incoming/
find /mnt/box/Incoming -maxdepth 2 -type f -print
```

Expected structure:

```text
Incoming/
  platform-engineer/job-offer.md
  platform-engineer/candidate-cv.md
  machine-learning-engineer/job-offer.md
  machine-learning-engineer/candidate-cv.md
  senior-product-designer/job-offer.md
  senior-product-designer/candidate-cv.md
```

These documents are fictional and intended only for demonstration.

## 5. Build in Cloud Build

```bash
./scripts/build.sh
```

The script prints the resulting immutable image digest. Save it:

```bash
export IMAGE_DIGEST="sha256:PASTE_DIGEST_HERE"
```

## 6. Run the one-shot review Job

```bash
export JOB_NAME="cv-review-box-ai-$(date +%s)"
./scripts/run-job.sh
```

The Job should print one line per processed role and write reports to:

```text
/mnt/box/Reviewed/<role>-candidate-review.md
```

The same reports should appear in the Box `Reviewed` folder after Box Mount sync completes.

## 7. Verify

```bash
kubectl -n box-demo get jobs,pods
kubectl -n box-demo logs job/$JOB_NAME -c cv-review
find /mnt/box/Reviewed -maxdepth 1 -type f -print
```

The report includes the Box file IDs used, the Box AI answer, returned citations, and a human-review disclaimer.

## Google Cloud documentation

These official guides cover the Google Cloud setup used by this repository:

- [Create and manage Google Cloud projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [Enable Google Cloud APIs](https://cloud.google.com/service-usage/docs/enable-disable)
- [Create a GKE Standard zonal cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-zonal-cluster)
- [Install `kubectl` and configure GKE access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl)
- [Create an Artifact Registry repository](https://cloud.google.com/artifact-registry/docs/repositories/create-repos)
- [Build container images with Cloud Build](https://cloud.google.com/build/docs/building/build-containers)
- [Deploy Artifact Registry images to GKE](https://cloud.google.com/artifact-registry/docs/integrate-gke)
- [Resize a GKE Standard node pool](https://cloud.google.com/kubernetes-engine/docs/how-to/resizing-a-cluster)

## Cost controls

Run the demo only when needed:

```bash
./scripts/scale-up.sh
./scripts/verify.sh
# run the Job
./scripts/scale-down.sh
```

Scaling the node pool to zero and stopping the admin VM removes the principal always-on compute cost. The GKE control plane, persistent resources, Artifact Registry storage, and any Filestore resources remain separate cost considerations. Delete unused Filestore resources explicitly when they are no longer needed.

## Security notes

This sample intentionally simplifies deployment for a live demonstration. Before considering a production implementation, review identity isolation, secret management, network controls, logging, monitoring, retries, concurrency, data retention, cost controls, and organizational policies with the appropriate security and privacy owners.

For this small demonstration, the trusted Box AI worker runs as `boxmount` because that user owns the JWT file and the Box Mount daemon. The general `agent` user remains available but is not used by this worker. A production design should isolate the credential-bearing Box API worker into a separate service or sidecar and use the narrowest Box app scopes and folder permissions possible.

Do not commit:

- Box JWT JSON files, private keys, or developer tokens;
- Kubernetes Secret manifests containing credentials;
- local gcloud or kubeconfig files; or
- the proprietary Box Mount binary.

## Optional Filestore / Agent Substrate follow-on

Filestore Agent Volumes and Agent Substrate are not required for this base workflow. Add them after the Box Mount + GKE path is stable. The natural extension is to use an Agent Volume for transient scratch space, model artifacts, or a shared review queue while keeping authoritative documents and reports in Box.
