# Cloud architecture – what each part does and why

This doc explains every cloud component in the Smart GTM Agent stack: **what it does**, **why we use it**, and **why we chose it over alternatives**.

---

## 1. Database: **RDS (PostgreSQL)** – why RDS, not others?

### What it does
- Runs a **PostgreSQL** database in AWS.
- Stores GTM plans, history, and any app data that must persist (your backend uses SQLAlchemy and talks to Postgres via `DATABASE_URL`).
- Lives in **private subnets** so only your backend (ECS) can reach it, not the internet.

### Why we use it
- The app is built for a **relational database** (SQLAlchemy, tables like plans/history). Postgres fits that model.
- You need **persistent storage** that survives container restarts and deploys. RDS gives you a managed database that is always on and backed up.

### Why RDS and not others?

| Option | Why we didn’t use it (for this app) |
|--------|-------------------------------------|
| **DynamoDB** | NoSQL key-value store. The app uses **relations** (e.g. plan ↔ history) and **SQL**. Rewriting to DynamoDB would mean a different data model and more code. RDS + Postgres matches the existing design. |
| **Aurora** | Same Postgres interface as RDS, but more expensive and aimed at high scale / multi-AZ. For a single-region app, **RDS Postgres** is simpler and cheaper. |
| **SQLite on ECS** | SQLite would live on the container filesystem. Every new deploy or new task = new file; data would not be shared or durable. **RDS** gives one shared, durable database for all backend tasks. |
| **DocumentDB** | MongoDB-compatible. The app isn’t built for document stores; it uses SQL and relations. No benefit here over Postgres. |

**Summary:** We use **RDS PostgreSQL** because the app is written for SQL and relations, and we need one shared, durable database that doesn’t disappear when we redeploy the backend.

---

## 2. Backend compute: **ECS Fargate** – why ECS, not others?

### What it does
- Runs your **FastAPI backend** inside a **Docker container**.
- **Fargate** = “serverless” containers: AWS runs the container for you; you don’t manage EC2 instances.
- ECS keeps the right number of tasks running, restarts them if they crash, and connects them to the load balancer.

### Why we use it
- The backend is a **long-running web server** (uvicorn). It needs to stay on, listen on a port, and handle many requests over time. A container on ECS fits that model.
- You already have a **Dockerfile**; ECS runs that image from ECR.

### Why ECS Fargate and not others?

| Option | Why we didn’t use it (for this app) |
|--------|-------------------------------------|
| **Lambda** | Lambda is for **short, event-driven** work (e.g. run for a few seconds per request). Your API has **state** (DB connections, in-memory caches), **long-running** calls (e.g. OpenAI), and **WebSockets** if you add them. Lambda is stateless and has time limits. **ECS** is better for a full web app. |
| **App Runner** | App Runner can run containers and is simpler. We chose **ECS + ALB** so we have full control over networking (VPC, private subnets, security groups) and can plug in RDS, Secrets Manager, and future services in the same VPC. |
| **EC2** | You’d manage the OS, patches, scaling, and load balancer yourself. **Fargate** gives you containers without managing servers. |

**Summary:** We use **ECS Fargate** because the backend is a stateful, long-running API that fits containers; Fargate runs those containers without you managing servers.

---

## 3. Load balancer: **ALB (Application Load Balancer)**

### What it does
- Sits in front of your ECS tasks. Users (and the frontend) call the **ALB URL**, not the container IP.
- Sends each request to a healthy ECS task (e.g. on port 8000). If a task dies, ALB stops sending traffic to it.
- Gives you **one stable URL** for the API even when tasks are replaced (new deploy, scale up/down).

### Why we use it
- ECS task IPs change. The frontend and any external clients need a **fixed endpoint**. The ALB provides that (e.g. `http://smart-gtm-agent-alb-xxx.us-east-1.elb.amazonaws.com`).
- Health checks (e.g. on `/api-key`) help ALB only route to tasks that are up.

### Why ALB and not others?
- **NLB** is for TCP/UDP and very high throughput; we need **HTTP** routing and path-based behavior. **ALB** is the standard for HTTP/HTTPS apps.
- **API Gateway** is often used with Lambda or as a single HTTP entry point; here the entry point is the **backend API**, so ALB in front of ECS is the right fit.

---

## 4. Networking: **VPC, subnets, NAT**

### What it does
- **VPC** = your own isolated network in AWS.
- **Public subnets** = ALB and NAT Gateway; they have a route to the internet.
- **Private subnets** = ECS tasks and RDS; no direct internet. ECS reaches the internet (e.g. OpenAI, ECR) through the **NAT Gateway** in a public subnet.

### Why we use it
- **Security:** RDS and backend run in private subnets so they aren’t directly exposed. Only the ALB is public.
- **Control:** You decide which traffic can reach the database and the app.

### Why this layout?
- Without a VPC, you’d put everything in the default VPC and have less control. Custom VPC + public/private subnets is the standard pattern for production apps with a database.

---

## 5. Container images: **ECR (Elastic Container Registry)**

### What it does
- Stores your **backend Docker images** (e.g. `smart-gtm-agent-backend:latest`).
- ECS pulls the image from ECR when it starts or updates a task.

### Why we use it
- ECS needs an image registry that’s in AWS and in the same VPC/network path. **ECR** is that registry; it works with IAM and doesn’t need a public Docker Hub.

### Why ECR and not others?
- **Docker Hub** can be used, but ECR is in your account, faster from ECS, and tied to IAM. For AWS-only deployments, **ECR** is the usual choice.

---

## 6. Secrets: **Secrets Manager**

### What it does
- Holds **sensitive values**: `DATABASE_URL` (Postgres connection string) and `OPENAI_API_KEY`.
- ECS task definition references these secrets by ARN; at runtime, the container gets the values as environment variables. You never put them in code or in the task definition as plain text.

### Why we use it
- **Security:** Keys and URLs aren’t in the image or in Terraform state in plain text. You rotate the secret in one place (Secrets Manager) and the next ECS deploy picks it up.
- **Operational:** You can update the OpenAI key in the console without rebuilding the image or changing Terraform (except if you change the secret name).

### Why Secrets Manager and not others?
- **SSM Parameter Store** can store secrets too; Secrets Manager is built for secrets (rotation, cross-account, audit). We use it for DB URL and API key.
- **Environment variables in Terraform** would put secrets in state; **Secrets Manager** keeps them out of state and centralizes access.

---

## 7. Frontend: **S3 + CloudFront**

### What it does
- **S3** = bucket holding the **built** frontend (HTML, JS, CSS from `npm run build`). No server runs here; it’s just files.
- **CloudFront** = CDN. It serves those S3 files from edge locations, and gives you an HTTPS URL (e.g. `https://d1234abcd.cloudfront.net`). Only CloudFront can read from the bucket (via OAI); the bucket is not public.

### Why we use it
- The frontend is a **static** React/Vite app. Static sites are cheap and fast when served from S3 + CloudFront. No EC2 or ECS needed for the UI.

### Why S3 + CloudFront and not others?
- **S3 website hosting** can serve static sites, but with HTTP and a less flexible URL. **CloudFront** gives HTTPS, custom domains, cache control, and keeps the bucket private.
- **Amplify Hosting** also does static + CDN; we use **S3 + CloudFront** so the same Terraform and CI/CD (sync to S3, invalidate CloudFront) work the same way and you own every piece.

---

## 8. CI/CD: **GitHub Actions**

### What it does
- **Terraform workflow:** On changes under `terraform/`, runs `plan` (on PRs) and `apply` (on push to main) so infra stays in sync with code.
- **Deploy workflow:** On push to main (or manual run): builds backend image → pushes to ECR → updates ECS service; builds frontend with `VITE_API_URL` → syncs to S3 → invalidates CloudFront.

### Why we use it
- **Automation:** Push code and get a new backend and frontend without running Docker/terraform/aws by hand.
- **Consistency:** Same steps every time; secrets (e.g. `BACKEND_URL`, `FRONTEND_BUCKET`) live in GitHub and are used at build/deploy time.

### Why GitHub Actions and not others?
- Repo is on GitHub; **Actions** is built in. Alternatives (e.g. AWS CodePipeline, GitLab CI) would do similar steps; we use Actions to keep everything in one place and reuse the same Terraform and deploy logic.

---

## End-to-end flow (how it fits together)

1. **User** opens the frontend URL (CloudFront → S3).
2. **Frontend** (React) calls the backend using `VITE_API_URL` (the ALB URL) for API requests.
3. **ALB** receives the request and forwards it to an **ECS** task (FastAPI).
4. **Backend** reads **Secrets Manager** (e.g. `OPENAI_API_KEY`, `DATABASE_URL`), talks to **RDS** for persistence and to **OpenAI** over the internet (via NAT).
5. **CI/CD** (GitHub Actions) builds new images and frontend, pushes to **ECR** and **S3**, updates **ECS** and invalidates **CloudFront**, so the next user gets the new version.

---

## Quick reference

| Component | What it does | Why this and not something else |
|-----------|--------------|----------------------------------|
| **RDS Postgres** | Managed SQL database for app data | App uses SQL/relations; need one shared, durable DB. Not DynamoDB/Aurora/SQLite for this design. |
| **ECS Fargate** | Runs backend container 24/7 | Long-running API with state and DB; fits containers. Not Lambda (stateless, time limits). |
| **ALB** | Single URL for API, forwards to ECS | Stable endpoint for frontend; HTTP health checks. |
| **VPC / subnets / NAT** | Isolated network; private app + DB | Security and control; standard pattern for prod. |
| **ECR** | Stores backend Docker image | ECS needs an image from AWS; ECR is the standard. |
| **Secrets Manager** | Holds DB URL and OpenAI key | No secrets in code or Terraform state; ECS injects at runtime. |
| **S3 + CloudFront** | Hosts static frontend over HTTPS | Static site; cheap and fast. CloudFront for HTTPS and private S3. |
| **GitHub Actions** | Terraform + build/deploy on push | Automate infra and app deploy from the repo. |
