# GitHub Secrets for starttech-application

Add under **Settings → Secrets and variables → Actions**.

## Required for all workflows

| Secret | Value (from your infra-aws / terraform output) |
|--------|--------------------------------------------------|
| `AWS_ACCESS_KEY_ID` | IAM access key |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key (same key pair as access key) |

## Frontend CI/CD

| Secret | Value |
|--------|--------|
| `S3_BUCKET` | `starttech-dev-frontend-051826713811` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `E2MH3GOFQYF8TO` |
| `CLOUDFRONT_DOMAIN` | `d3tp2sespfhcea.cloudfront.net` |
| `VITE_API_BASE_URL` | `http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com` |

## Backend CI/CD

| Secret | Value |
|--------|--------|
| `ECR_REPOSITORY` | `starttech-dev-backend` |
| `ASG_NAME` | `starttech-dev-asg` |
| `ALB_TARGET_GROUP_ARN` | `arn:aws:elasticloadbalancing:us-east-1:051826713811:targetgroup/starttech-dev-tg/5b4c7a34f159b1a0` |
| `API_URL` | `http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com` |
| `MONGO_URI` | MongoDB Atlas connection string |
| `DB_NAME` | `much_todo_db` |
| `JWT_SECRET_KEY` | Your JWT secret |
| `REDIS_ADDR` | `starttech-dev-redis.v0ue35.ng.0001.use1.cache.amazonaws.com:6379` |
| `ALLOWED_ORIGINS` | `https://d3tp2sespfhcea.cloudfront.net,http://starttech-dev-alb-1473945814.us-east-1.elb.amazonaws.com` |
| `CLOUDWATCH_LOG_GROUP` | `/starttech/dev/backend` |
