# StartTech Application Runbook

## Deploy frontend (CI/CD)

1. Push to `main` with changes under `frontend/`.
2. Workflow **Frontend CI/CD** runs: test → lint → build → S3 sync → CloudFront invalidation.
3. Verify:

   ```bash
   aws s3 ls s3://starttech-dev-frontend-051826713811/
   curl -I https://d3tp2sespfhcea.cloudfront.net
   ```

Manual deploy:

```bash
cd frontend
export VITE_API_BASE_URL=http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com
npm ci && npm run build
cd ..
export S3_BUCKET=starttech-dev-frontend-051826713811
export CLOUDFRONT_DISTRIBUTION_ID=E2MH3GOFQYF8TO
bash scripts/deploy-frontend.sh
```

## Deploy backend (CI/CD)

**Required GitHub Secrets:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `MONGO_URI`, `JWT_SECRET_KEY`

1. Push to `main` with changes under `backend/`.
2. Workflow **Backend CI/CD**: unit + integration tests → Docker build → ECR push → SSM rolling deploy → `/health` smoke test.
3. Verify:

   ```bash
   curl http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com/health
   aws ssm describe-instance-information
   ```

## Health check

```bash
export API_URL=http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com
bash scripts/health-check.sh
```

Expected: HTTP 200 with `"database":"ok"`.

## Rollback backend

```bash
export PREVIOUS_IMAGE_TAG=<older-commit-sha>
# Set same env vars as deploy-backend.sh (see GITHUB_SECRETS.md)
bash scripts/rollback.sh
```

## Troubleshooting

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| CloudFront 403/blank | Empty S3 or invalidation pending | Re-run frontend workflow |
| API 502/503 | No healthy targets | Check backend deploy; `aws elbv2 describe-target-health` |
| CORS errors | Wrong `ALLOWED_ORIGINS` | Include CloudFront + ALB URLs |
| MongoDB down in `/health` | Atlas network access | Allow `0.0.0.0/0` or NAT IP in Atlas |
| SSM deploy fails | Instances not registered | Wait 10 min after IAM SSM policy; check `AmazonSSMManagedInstanceCore` |

## Logs

Backend logs: CloudWatch log group `/starttech/dev/backend` (stream prefix `backend`).

Example Logs Insights queries: `starttech-infra/monitoring/log-insights-queries.txt`
