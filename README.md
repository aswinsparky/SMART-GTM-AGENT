# Smart GTM Agent (Local, no Docker)

This repository contains a full-stack local app that generates AI-based go-to-market strategies.

## Quick start

### Backend

1. Create and activate virtualenv

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # or .\\venv\\Scripts\\activate on Windows
pip install -r requirements.txt
```

2. Copy `.env.example` to `.env` and add your OpenAI API key:

```bash
cp .env.example .env
# then edit .env and set OPENAI_API_KEY=sk-...
```

3. Run backend

```bash
uvicorn main:app --reload --port 8000
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Open the frontend (usually http://localhost:5173) and the backend at http://localhost:8000.

## Notes
- For local development we support saving API key to `.env` via `/api-key` endpoint. In production, use a secrets manager.
- SQLite DB file will be created automatically in backend directory.

## Cloud deployment
- **Terraform + AWS + CI/CD**: See **[docs/TERRAFORM_AWS_CICD.md](docs/TERRAFORM_AWS_CICD.md)** for Terraform, AWS (ECS, RDS, S3, CloudFront), and GitHub Actions pipelines.
- **Other clouds**: See **[docs/CLOUD_SETUP.md](docs/CLOUD_SETUP.md)** for Vercel, Railway, or Render.
