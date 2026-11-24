#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${CLUSTER:?Set CLUSTER}"
: "${ZONE:?Set ZONE}"
: "${BOX_ROOT_FOLDER_ID:?Set BOX_ROOT_FOLDER_ID}"
: "${IMAGE_DIGEST:?Set IMAGE_DIGEST, for example sha256:...}"
: "${BOX_JWT_SECRET_KEY:?Set BOX_JWT_SECRET_KEY to the filename inside the Kubernetes Secret}"

REGION="${REGION:-us-central1}"
REPOSITORY="${REPOSITORY:-agent-demo}"
IMAGE_NAME="${IMAGE_NAME:-box-agent}"
BOX_JWT_SECRET_NAME="${BOX_JWT_SECRET_NAME:-box-mount-jwt}"
JOB_NAME="${JOB_NAME:-cv-review-box-ai-$(date +%s)}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}@${IMAGE_DIGEST}"

gcloud container clusters get-credentials "$CLUSTER" \
  --project="$PROJECT_ID" \
  --zone="$ZONE"

export JOB_NAME IMAGE BOX_ROOT_FOLDER_ID BOX_JWT_SECRET_NAME BOX_JWT_SECRET_KEY
envsubst < k8s/job.yaml.tmpl | kubectl apply -f -

kubectl -n box-demo logs -f "job/$JOB_NAME" -c cv-review
