# GitHub Secrets for starttech-application

## Required (minimum)

| Secret | Notes |
|--------|--------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | Matching secret key |
| `MONGO_URI` | MongoDB Atlas connection string |
| `JWT_SECRET_KEY` | Backend auth secret |

## Optional overrides

Deploy targets are set in workflow `env` blocks. Override only if your Terraform outputs differ:

`S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, `ECR_REPOSITORY`, `ASG_NAME`, `MONGO_URI`, etc.

## Infra repo secrets

`starttech-infra` needs only:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
