# StartTech Application

Much To Do — React frontend and Golang backend with GitHub Actions CI/CD to AWS.

**Documentation:** [ARCHITECTURE.md](./ARCHITECTURE.md) · [RUNBOOK.md](./RUNBOOK.md) · [GITHUB_SECRETS.md](./GITHUB_SECRETS.md)

**Infrastructure repo:** https://github.com/samolamide/starttech-infra

## Repository layout

```
frontend/          # React (Vite)
backend/           # Golang API + Dockerfile
scripts/           # deploy-frontend.sh, deploy-backend.sh, health-check.sh, rollback.sh
.github/workflows/ # frontend-ci-cd.yml, backend-ci-cd.yml
```

## GitHub Secrets (required)

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | Deploy to AWS |
| `AWS_SECRET_ACCESS_KEY` | Deploy to AWS |
| `MONGO_URI` | MongoDB Atlas |
| `JWT_SECRET_KEY` | API authentication |

S3, CloudFront, ECR, ASG, and other deploy targets are configured in workflow `env` blocks.

## Pipelines

| Workflow | Stages |
|----------|--------|
| **Frontend CI/CD** | npm ci → test → lint → audit → build → S3 → CloudFront invalidation |
| **Backend CI/CD** | unit + integration tests → go vet → govulncheck → Docker → Trivy → ECR → SSM rolling deploy → smoke test |

## Live URLs

| Service | URL |
|---------|-----|
| Frontend | https://d3tp2sespfhcea.cloudfront.net |
| API | http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com |
| Health | http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com/health |

## Local development

```bash
# Frontend
cd frontend && npm install && npm run dev

# Backend (requires MongoDB/Redis or .env)
cd backend && go run ./cmd/api/main.go
```

See [RUNBOOK.md](./RUNBOOK.md) for deploy, rollback, and troubleshooting.
