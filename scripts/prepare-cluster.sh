#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${CLUSTER:?Set CLUSTER}"
: "${ZONE:?Set ZONE}"
: "${JWT_FILE:?Set JWT_FILE to the Box JWT JSON file}"

BOX_JWT_SECRET_NAME="${BOX_JWT_SECRET_NAME:-box-mount-jwt}"
if [[ -z "${BOX_JWT_SECRET_KEY:-}" ]]; then
  BOX_JWT_SECRET_KEY="$(basename "$JWT_FILE")"
fi

gcloud container clusters get-credentials "$CLUSTER" \
  --project="$PROJECT_ID" \
  --zone="$ZONE"

kubectl create namespace box-demo --dry-run=client -o yaml | kubectl apply -f -

kubectl -n box-demo create secret generic "$BOX_JWT_SECRET_NAME" \
  --from-file="$BOX_JWT_SECRET_KEY=$JWT_FILE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Prepared namespace box-demo and Secret $BOX_JWT_SECRET_NAME"
echo "Secret key: $BOX_JWT_SECRET_KEY"
