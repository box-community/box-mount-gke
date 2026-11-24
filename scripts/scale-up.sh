#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${CLUSTER:?Set CLUSTER}"
: "${ZONE:?Set ZONE}"

NODE_POOL="${NODE_POOL:-default-pool}"
ADMIN_VM="${ADMIN_VM:-agent-demo-admin}"
START_ADMIN_VM="${START_ADMIN_VM:-true}"

if [[ "$START_ADMIN_VM" == "true" ]]; then
  gcloud compute instances start "$ADMIN_VM" \
    --project="$PROJECT_ID" \
    --zone="$ZONE"
fi

gcloud container clusters resize "$CLUSTER" \
  --node-pool="$NODE_POOL" \
  --num-nodes=1 \
  --project="$PROJECT_ID" \
  --zone="$ZONE"

echo "Demo scaled up to one node. Wait for the node to become Ready before running the Job."
