#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"

REGION="${REGION:-us-central1}"
REPOSITORY="${REPOSITORY:-agent-demo}"
IMAGE_NAME="${IMAGE_NAME:-box-agent}"
IMAGE_TAG="${IMAGE_TAG:-v0.1}"

gcloud builds submit \
  --project="$PROJECT_ID" \
  --config=cloudbuild.yaml \
  --region="$REGION" \
  --substitutions="_REGION=$REGION,_REPOSITORY=$REPOSITORY,_IMAGE=$IMAGE_NAME,_TAG=$IMAGE_TAG" \
  .

IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"
gcloud artifacts docker images describe "$IMAGE_URI" \
  --project="$PROJECT_ID" \
  --format='value(image_summary.digest)'
