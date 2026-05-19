#!/usr/bin/env bash
set -euo pipefail

: "${S3_BUCKET:?S3_BUCKET is required}"
: "${CLOUDFRONT_DISTRIBUTION_ID:?CLOUDFRONT_DISTRIBUTION_ID is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/frontend/dist"

if [[ ! -d "${DIST_DIR}" ]]; then
  echo "Build output not found at ${DIST_DIR}. Run npm run build first."
  exit 1
fi

echo "==> Syncing to s3://${S3_BUCKET}"
aws s3 sync "${DIST_DIR}/" "s3://${S3_BUCKET}/" --delete

echo "==> Invalidating CloudFront cache"
INVALIDATION_ID="$(aws cloudfront create-invalidation \
  --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text)"

echo "Invalidation started: ${INVALIDATION_ID}"
aws cloudfront wait invalidation-completed \
  --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
  --id "${INVALIDATION_ID}"

echo "==> Frontend deployment complete"
