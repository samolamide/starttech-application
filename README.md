# StartTech Application — Phase 2 CI/CD

React frontend (S3 + CloudFront) and Golang backend (ECR → EC2 ASG via SSM rolling deploy).

## Repository layout

```
frontend/          # React (Vite)
backend/           # Golang API + Dockerfile
scripts/           # deploy-frontend.sh, deploy-backend.sh, health-check.sh, rollback.sh
.github/workflows/
  frontend-ci-cd.yml
  backend-ci-cd.yml
```

## GitHub Secrets (required)

Create these in **Settings → Secrets and variables → Actions** on your `starttech-application` repo:

| Secret | Example / source |
|--------|------------------|
| `AWS_ACCESS_KEY_ID` | IAM user with deploy permissions |
| `AWS_SECRET_ACCESS_KEY` | Same IAM user |
| `S3_BUCKET` | `starttech-dev-frontend-051826713811` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `E2MH3GOFQYF8TO` |
| `CLOUDFRONT_DOMAIN` | `d3tp2sespfhcea.cloudfront.net` (optional, notifications) |
| `VITE_API_BASE_URL` | `http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com` |
| `ECR_REPOSITORY` | `starttech-dev-backend` (after `terraform apply` in infra repo) |
| `ASG_NAME` | `starttech-dev-asg` |
| `ALB_TARGET_GROUP_ARN` | From `terraform output alb_target_group_arn` |
| `API_URL` | Same as ALB URL (for health checks) |
| `MONGO_URI` | From MongoDB Atlas (see `infra-aws`) |
| `DB_NAME` | `much_todo_db` |
| `JWT_SECRET_KEY` | From `infra-aws` |
| `REDIS_ADDR` | `starttech-dev-redis....amazonaws.com:6379` |
| `ALLOWED_ORIGINS` | `https://d3tp2sespfhcea.cloudfront.net,http://starttech-dev-alb-....elb.amazonaws.com` |
| `CLOUDWATCH_LOG_GROUP` | `/starttech/dev/backend` |

## IAM permissions for CI user

Attach policies (or inline) allowing at minimum:

- `ecr:*` (push images)
- `s3:PutObject`, `s3:DeleteObject`, `s3:ListBucket` on frontend bucket
- `cloudfront:CreateInvalidation`
- `ssm:SendCommand`, `ssm:GetCommandInvocation`, `ssm:ListCommandInvocations`
- `ec2:DescribeInstances`
- `autoscaling:DescribeAutoScalingGroups`, `autoscaling:DescribePolicies`
- `elasticloadbalancing:DescribeTargetHealth`

## Local commands

```bash
# Frontend
cd frontend && npm install && npm test && npm run build

# Backend
cd backend && go test ./... && docker build -t starttech-backend:local .
```

## Pipelines

- **frontend-ci-cd.yml** — test → build → S3 sync → CloudFront invalidation
- **backend-ci-cd.yml** — test → Docker build → Trivy scan → ECR push → SSM rolling deploy → `/health` smoke test

## Rollback

Re-run deploy with a previous image tag:

```bash
export PREVIOUS_IMAGE_TAG=<older-git-sha>
# plus all other env vars from deploy-backend.sh
bash scripts/rollback.sh
```

## Notes

- EC2 instances must be **InService** in the ASG and registered with **SSM** (IAM role includes `AmazonSSMManagedInstanceCore`).
- After first infra deploy, run `terraform apply` in `starttech-infra` to create the **ECR** repository before the backend pipeline.
