#!/usr/bin/env bash
set -euo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${ECR_REPOSITORY:?ECR_REPOSITORY is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"
: "${ASG_NAME:?ASG_NAME is required}"
: "${MONGO_URI:?MONGO_URI is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${JWT_SECRET_KEY:?JWT_SECRET_KEY is required}"
: "${REDIS_ADDR:?REDIS_ADDR is required}"
: "${ALLOWED_ORIGINS:?ALLOWED_ORIGINS is required}"
: "${CLOUDWATCH_LOG_GROUP:?CLOUDWATCH_LOG_GROUP is required}"

b64() { printf '%s' "$1" | base64 | tr -d '\n'; }

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_IMAGE="${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
TARGET_GROUP_ARN="${TARGET_GROUP_ARN:-}"

MONGO_URI_B64="$(b64 "${MONGO_URI}")"
JWT_B64="$(b64 "${JWT_SECRET_KEY}")"
DB_NAME_B64="$(b64 "${DB_NAME}")"
REDIS_B64="$(b64 "${REDIS_ADDR}")"
ORIGINS_B64="$(b64 "${ALLOWED_ORIGINS}")"

echo "==> Deploying ${ECR_IMAGE} to ASG ${ASG_NAME} (rolling)"

INSTANCE_IDS="$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "${ASG_NAME}" \
  --query 'AutoScalingGroups[0].Instances[?LifecycleState==`InService`].InstanceId' \
  --output text)"

if [[ -z "${INSTANCE_IDS}" || "${INSTANCE_IDS}" == "None" ]]; then
  echo "No InService instances found in ASG ${ASG_NAME}"
  exit 1
fi

# Only deploy to instances registered with SSM (required for Run Command)
SSM_READY=""
echo "==> Checking SSM registration for instances: ${INSTANCE_IDS}"
for attempt in $(seq 1 36); do
  SSM_READY=""
  for INSTANCE_ID in ${INSTANCE_IDS}; do
    PING="$(aws ssm describe-instance-information \
      --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
      --query 'InstanceInformationList[0].PingStatus' \
      --output text 2>/dev/null || echo "None")"
    if [[ "${PING}" == "Online" ]]; then
      SSM_READY="${SSM_READY} ${INSTANCE_ID}"
    else
      echo "Instance ${INSTANCE_ID} SSM status: ${PING}"
    fi
  done
  if [[ -n "${SSM_READY// /}" ]]; then
    break
  fi
  echo "Waiting for SSM agent (attempt ${attempt}/36)..."
  sleep 10
done

if [[ -z "${SSM_READY// /}" ]]; then
  echo "ERROR: No instances are Online in SSM. Run an ASG instance refresh after terraform apply:"
  echo "  aws autoscaling start-instance-refresh --auto-scaling-group-name ${ASG_NAME}"
  exit 1
fi

INSTANCE_IDS="${SSM_READY}"
echo "==> SSM-ready instances:${INSTANCE_IDS}"

read -r -d '' REMOTE_SCRIPT <<EOS || true
#!/bin/bash
set -eux
export MONGO_URI="\$(echo '${MONGO_URI_B64}' | base64 -d)"
export JWT_SECRET_KEY="\$(echo '${JWT_B64}' | base64 -d)"
export DB_NAME="\$(echo '${DB_NAME_B64}' | base64 -d)"
export REDIS_ADDR="\$(echo '${REDIS_B64}' | base64 -d)"
export ALLOWED_ORIGINS="\$(echo '${ORIGINS_B64}' | base64 -d)"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker pull ${ECR_IMAGE}
docker stop starttech-backend 2>/dev/null || true
docker rm starttech-backend 2>/dev/null || true
# Use default json-file logging (awslogs driver is unreliable on AL2023 stock Docker)
docker run -d --name starttech-backend --restart unless-stopped -p 8080:8080 \
  -e PORT=8080 \
  -e MONGO_URI="\$MONGO_URI" \
  -e DB_NAME="\$DB_NAME" \
  -e JWT_SECRET_KEY="\$JWT_SECRET_KEY" \
  -e ENABLE_CACHE=true \
  -e REDIS_ADDR="\$REDIS_ADDR" \
  -e ALLOWED_ORIGINS="\$ALLOWED_ORIGINS" \
  -e SECURE_COOKIE=false \
  -e LOG_LEVEL=INFO \
  -e LOG_FORMAT=json \
  ${ECR_IMAGE}
sleep 5
docker ps --filter name=starttech-backend
curl -fsS http://127.0.0.1:8080/health
EOS

# Build JSON array of commands for SSM (one command per line)
if command -v jq >/dev/null 2>&1; then
  COMMANDS_JSON="$(printf '%s\n' "${REMOTE_SCRIPT}" | jq -R -s 'split("\n") | map(select(length > 0))')"
elif command -v python3 >/dev/null 2>&1; then
  COMMANDS_JSON="$(printf '%s\n' "${REMOTE_SCRIPT}" | python3 -c "import json,sys; print(json.dumps([l for l in sys.stdin.read().splitlines() if l]))")"
else
  echo "ERROR: install jq or python3 to build SSM command payload"
  exit 1
fi

for INSTANCE_ID in ${INSTANCE_IDS}; do
  echo "==> Deploying to instance ${INSTANCE_ID}"
  COMMAND_ID="$(aws ssm send-command \
    --instance-ids "${INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --comment "Deploy StartTech backend ${IMAGE_TAG}" \
    --parameters "{\"commands\":${COMMANDS_JSON}}" \
    --query 'Command.CommandId' \
    --output text)"

  echo "SSM command: ${COMMAND_ID}"
  for i in $(seq 1 60); do
    STATUS="$(aws ssm get-command-invocation \
      --command-id "${COMMAND_ID}" \
      --instance-id "${INSTANCE_ID}" \
      --query 'Status' \
      --output text 2>/dev/null || echo "Pending")"
    if [[ "${STATUS}" == "Success" ]]; then
      echo "SSM deploy succeeded on ${INSTANCE_ID}"
      break
    fi
    if [[ "${STATUS}" == "Failed" || "${STATUS}" == "Cancelled" || "${STATUS}" == "TimedOut" ]]; then
      aws ssm get-command-invocation --command-id "${COMMAND_ID}" --instance-id "${INSTANCE_ID}"
      exit 1
    fi
    sleep 5
  done

  if [[ -n "${TARGET_GROUP_ARN}" ]]; then
    echo "==> Waiting for ${INSTANCE_ID} to pass ALB health checks"
    for i in $(seq 1 30); do
      STATE="$(aws elbv2 describe-target-health \
        --target-group-arn "${TARGET_GROUP_ARN}" \
        --targets "Id=${INSTANCE_ID}" \
        --query 'TargetHealthDescriptions[0].TargetHealth.State' \
        --output text 2>/dev/null || echo "unknown")"
      if [[ "${STATE}" == "healthy" ]]; then
        echo "Instance ${INSTANCE_ID} is healthy"
        break
      fi
      echo "Target health: ${STATE} (${i}/30)"
      sleep 10
    done
  fi
done

echo "==> Backend rolling deployment complete"
