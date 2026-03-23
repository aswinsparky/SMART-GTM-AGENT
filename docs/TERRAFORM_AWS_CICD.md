# Terraform + AWS + CI/CD

This guide covers deploying Smart GTM Agent with **Terraform** on **AWS** and **GitHub Actions** CI/CD.

## Terraform module layout

Infrastructure is split into reusable modules under `terraform/modules/`:

| Module     | Purpose |
|-----------|---------|
| **vpc**   | VPC, public/private subnets, NAT gateway, route tables |
| **ecr**   | ECR repository and lifecycle policy for backend image |
| **alb**   | Application Load Balancer, target group, HTTP listener |
| **security** | Security groups for ECS tasks and RDS |
| **rds**   | RDS PostgreSQL, subnet group, random password |
| **secrets** | Secrets Manager: `DATABASE_URL`, `OPENAI_API_KEY` |
| **ecs**   | ECS cluster, task definition, service, IAM roles, CloudWatch log group |
| **frontend** | S3 bucket, CloudFront OAI, distribution (SPA) |
| **ec2_backend** | EC2 + ASG behind ALB (alternative to ECS) |

The root `terraform/` wires these together in `main.tf` and exposes outputs in `outputs.tf`. You can change or reuse modules (e.g. different VPC or RDS settings) without touching others.

### EC2 vs ECS backend

You can run the backend on **EC2** instead of **ECS Fargate**: same ALB, same backend image in ECR, same RDS and Secrets Manager. Set in `terraform.tfvars`:

```hcl
backend_type = "ec2"
ec2_instance_type = "t3.micro"
ec2_min_size      = 1
ec2_max_size      = 2
```

- **ECS**: Serverless containers, no OS to manage, scale by task count.
- **EC2**: One or more instances in an ASG; launch template runs Docker and pulls the backend image from ECR; instances register with the ALB target group. Good if you prefer VMs or want to SSH into the box.

For CI/CD with EC2, set GitHub variable **BACKEND_TYPE** = `ec2` so the deploy workflow runs an ASG instance refresh instead of an ECS deployment. **Push the backend image to ECR at least once before** the first Terraform apply with `backend_type = "ec2"`, so the EC2 user data can pull `:latest`.

## Architecture

| Component   | AWS service           | Purpose |
|------------|------------------------|---------|
| Backend    | ECS Fargate + ALB      | Run FastAPI in a container |
| Database   | RDS PostgreSQL         | Persistent data |
| Frontend  | S3 + CloudFront        | Static React app |
| Secrets   | Secrets Manager         | `OPENAI_API_KEY`, `DATABASE_URL` |
| Images    | ECR                    | Backend Docker image |

## Prerequisites

- AWS account and CLI configured
- Terraform >= 1.5
- GitHub repo with the project
- (Optional) GitHub OIDC for AWS to avoid long-lived keys

---

## 1. Terraform state backend (recommended)

Create an S3 bucket and DynamoDB table for remote state and locking (one-time, separate from app Terraform):

```bash
# Create bucket and table (replace REGION and BUCKET_NAME)
aws s3 mb s3://YOUR-TERRAFORM-STATE-BUCKET --region us-east-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

In `terraform/backend.tf` (create the file), uncomment and set:

```hcl
backend "s3" {
  bucket         = "YOUR-TERRAFORM-STATE-BUCKET"
  key            = "smart-gtm-agent/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

Then run `terraform init -reconfigure` in `terraform/`.

---

## 2. Apply Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # edit if needed
terraform init
terraform plan
terraform apply
```

After apply:

- Note **backend_url** (ALB) and **frontend_url** (CloudFront) from `terraform output`.
- Set the **OPENAI_API_KEY** secret value in AWS Console: Secrets Manager → `smart-gtm-agent/openai-api-key` → Store a new secret value (your key).

---

## 3. GitHub Actions – AWS credentials

Choose one:

### Option A: OIDC (recommended, no long-lived keys)

1. In AWS: create an IAM OIDC identity provider for GitHub (e.g. `token.actions.githubusercontent.com`).
2. Create an IAM role that trusts your repo and has policy allowing ECR push, ECS update, S3 sync, CloudFront invalidate, Secrets Manager read (for ECS), ELB describe.
3. Copy the role ARN and add it as a GitHub secret: **AWS_ROLE_ARN**.

### Option B: Access keys

1. Create an IAM user with policies for ECR, ECS, S3, CloudFront, Secrets Manager (as above).
2. Add GitHub secrets: **AWS_ACCESS_KEY_ID**, **AWS_SECRET_ACCESS_KEY**.
3. In the workflow files, switch from `role-to-assume` to `aws-access-key-id` / `aws-secret-access-key` (see comments in the workflow).

---

## 4. GitHub secrets for Deploy workflow

Set these in the repo: **Settings → Secrets and variables → Actions**:

| Secret                 | Description |
|------------------------|-------------|
| **AWS_ROLE_ARN**       | IAM role ARN (OIDC) or leave empty if using access keys |
| **AWS_ACCESS_KEY_ID**  | (If not using OIDC) |
| **AWS_SECRET_ACCESS_KEY** | (If not using OIDC) |
| **BACKEND_URL**        | Backend API base URL, e.g. `http://smart-gtm-agent-alb-xxx.us-east-1.elb.amazonaws.com` (from `terraform output backend_url`) |
| **FRONTEND_BUCKET**    | S3 bucket name for frontend (from `terraform output frontend_bucket`) |
| **CLOUDFRONT_DIST_ID** | CloudFront distribution ID (from `terraform output cloudfront_distribution_id`) |

---

## 5. Workflows

- **`.github/workflows/terraform.yml`**  
  - Runs on changes under `terraform/`.  
  - `terraform plan` on PRs; `terraform apply` on push to `main` (if you use branch protection, require approval before apply).

- **`.github/workflows/deploy.yml`**  
  - On push to `main` (under `backend/` or `frontend/`) or manual trigger:  
    - Builds backend image, pushes to ECR, forces new ECS deployment.  
    - Builds frontend with `VITE_API_URL=$BACKEND_URL`, syncs to S3, invalidates CloudFront.

---

## 6. First-time deploy order

1. Apply Terraform (creates ECR, RDS, ECS, ALB, S3, CloudFront, secrets).
2. Set **OPENAI_API_KEY** in Secrets Manager (see step 2).
3. Set GitHub secrets (step 4).
4. Push to `main` or run **Deploy** workflow manually: first run pushes the image and updates ECS; frontend build uses **BACKEND_URL** and deploys to S3/CloudFront.
5. Open the **frontend_url** from Terraform output.

---

## 6b. Manual deploy: push backend image from your machine

If you build and push the backend image locally (e.g. before CI is set up), **you must build for linux/amd64**. ECS Fargate and typical EC2 instances use x86_64; a build on Apple Silicon (ARM) produces an arm64 image that ECS cannot run and will fail with "image Manifest does not contain descriptor matching platform 'linux/amd64'".

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 818916266868.dkr.ecr.us-east-1.amazonaws.com
cd backend
docker build --platform linux/amd64 -t 818916266868.dkr.ecr.us-east-1.amazonaws.com/smart-gtm-agent-backend:latest .
docker push 818916266868.dkr.ecr.us-east-1.amazonaws.com/smart-gtm-agent-backend:latest
aws ecs update-service --cluster smart-gtm-agent-cluster --service smart-gtm-agent-backend --force-new-deployment --region us-east-1
```

Replace the ECR registry ID and region if yours differ. The GitHub Deploy workflow already uses `--platform linux/amd64` when building the image.

---

## 7. Optional: restrict CORS

To lock the API to your frontend only, set `allowed_cors_origins` in `terraform.tfvars` to your CloudFront URL (e.g. `https://d1234.cloudfront.net`) and ensure the FastAPI app uses it (you may need to expose it as an env var and use it in the CORS middleware).

---

## 8. Cost notes

- RDS (db.t3.micro), NAT Gateway, and Fargate have cost. Use **FARGATE_SPOT** in ECS for lower cost; consider tearing down or scaling to zero in non-prod.
