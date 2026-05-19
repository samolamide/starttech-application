# StartTech Application Architecture

This repository contains the **Much To Do** full-stack application and CI/CD pipelines. AWS infrastructure is defined in the companion repo **starttech-infra**.

## Request flow

1. User loads the React SPA from **CloudFront** → **S3**.
2. Browser calls the API at the **ALB** URL (`VITE_API_BASE_URL` at build time).
3. **ALB** forwards to an **EC2** instance (Docker) running the Golang API on port **8080**.
4. API reads/writes **MongoDB Atlas** and optionally **ElastiCache Redis**.
5. Application logs ship to **CloudWatch** via the Docker `awslogs` driver.

See [starttech-infra/ARCHITECTURE.md](https://github.com/samolamide/starttech-infra/blob/main/ARCHITECTURE.md) for the full infrastructure diagram.

## Repository layout

| Path | Description |
|------|-------------|
| `frontend/` | React + Vite SPA |
| `backend/` | Golang API + Dockerfile |
| `scripts/` | Deploy, health-check, rollback shell scripts |
| `.github/workflows/` | Frontend and backend CI/CD |

## Environment configuration

| Variable | Where set | Purpose |
|----------|-----------|---------|
| `VITE_API_BASE_URL` | GitHub Actions workflow `env` | API URL baked into React build |
| `MONGO_URI` | GitHub Secret | MongoDB Atlas connection |
| `JWT_SECRET_KEY` | GitHub Secret | Auth token signing |
| `REDIS_ADDR`, `ALLOWED_ORIGINS`, etc. | Workflow `env` | Backend container runtime |

## Health endpoint

`GET /health` — returns database and cache status; used by ALB and smoke tests.
