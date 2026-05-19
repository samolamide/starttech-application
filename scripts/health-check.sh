#!/usr/bin/env bash
set -euo pipefail

: "${API_URL:?API_URL is required}"

# Full dependency check (may return 503 if Mongo/Redis down)
HEALTH_URL="${API_URL%/}/health"
PING_URL="${API_URL%/}/ping"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-60}"
SLEEP_SECONDS="${SLEEP_SECONDS:-15}"

echo "==> ALB liveness check: ${PING_URL}"
echo "==> Full health check: ${HEALTH_URL}"

for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
  if curl -fsS "${PING_URL}" >/dev/null; then
    echo "Ping check passed on attempt ${attempt}"
    curl -fsS "${PING_URL}"
    echo
    echo "Full /health response:"
    curl -sS "${HEALTH_URL}" | head -c 500 || true
    echo
    exit 0
  fi
  echo "Attempt ${attempt}/${MAX_ATTEMPTS} failed; retrying in ${SLEEP_SECONDS}s..."
  sleep "${SLEEP_SECONDS}"
done

echo "Health check failed after ${MAX_ATTEMPTS} attempts"
exit 1
