#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${CLUSTER:?Set CLUSTER}"
: "${ZONE:?Set ZONE}"

gcloud container clusters describe "$CLUSTER" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --format='table(name,status,currentMasterVersion)'

kubectl get nodes -o wide
kubectl -n box-demo get secret box-mount-jwt
