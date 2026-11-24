#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${CLUSTER:?Set CLUSTER}"
: "${ZONE:?Set ZONE}"

NODE_POOL="${NODE_POOL:-default-pool}"
ADMIN_VM="${ADMIN_VM:-agent-demo-admin}"
STOP_ADMIN_VM="${STOP_ADMIN_VM:-true}"

gcloud container clusters resize "$CLUSTER" \
  --node-pool="$NODE_POOL" \
  --num-nodes=0 \
  --project="$PROJECT_ID" \
  --zone="$ZONE"

if [[ "$STOP_ADMIN_VM" == "true" ]]; then
  gcloud compute instances stop "$ADMIN_VM" \
    --project="$PROJECT_ID" \
    --zone="$ZONE"
fi

echo "Demo scaled down. Persistent storage and Box content are unchanged."
