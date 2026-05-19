#!/usr/bin/env bash
set -euo pipefail

: "${API_URL:?API_URL is required}"

HEALTH_URL="${API_URL%/}/health"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
SLEEP_SECONDS="${SLEEP_SECONDS:-10}"

echo "==> Health check: ${HEALTH_URL}"

for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  if curl -fsS "${HEALTH_URL}" >/dev/null; then
    echo "Health check passed on attempt ${attempt}"
    curl -fsS "${HEALTH_URL}" | head -c 500
    echo
    exit 0
  fi
  echo "Attempt ${attempt}/${MAX_ATTEMPTS} failed; retrying in ${SLEEP_SECONDS}s..."
  sleep "${SLEEP_SECONDS}"
done

echo "Health check failed after ${MAX_ATTEMPTS} attempts"
exit 1
