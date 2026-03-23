# Cloud deployment guide – Smart GTM Agent

Recommended setup for running the app in the cloud: **frontend on Vercel**, **backend + DB on Railway or Render**. All have free tiers and minimal config.

---

## Recommended stack

| Layer      | Service   | Why |
|-----------|-----------|-----|
| **Frontend** | [Vercel](https://vercel.com) | Free tier, great for React/Vite, global CDN |
| **Backend**  | [Railway](https://railway.app) or [Render](https://render.com) | Run FastAPI + Postgres, simple env and secrets |
| **Database** | Postgres (Railway/Render add-on or [Supabase](https://supabase.com)) | Managed Postgres, replace SQLite in production |
| **Secrets**  | Env vars on backend host | `OPENAI_API_KEY` and `DATABASE_URL`; optional: provider secret manager |

---

## 1. Backend (Railway or Render)

### Option A: Railway

1. Sign up at [railway.app](https://railway.app).
2. **New Project** → **Deploy from GitHub** (connect repo) or **Empty Project** and deploy with CLI.
3. Add **Postgres** from the same project (one-click; Railway sets `DATABASE_URL`).
4. Add a **Service** for the backend:
   - **Source**: GitHub repo, root directory → `SMART-GTM-AGENT/backend` (or deploy with Dockerfile below).
   - **Build**: Dockerfile in `backend/` or:
     - Build command: `pip install -r requirements.txt`
     - Start: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Variables** (in Railway dashboard):
     - `OPENAI_API_KEY` = your OpenAI key
     - `DATABASE_URL` = (auto-set if you added Postgres; otherwise your Postgres URL)
     - `MOCK_MODE` = `0` (or `1` to skip OpenAI)
5. Deploy. Note the public URL (e.g. `https://your-app.up.railway.app`).

### Option B: Render

1. Sign up at [render.com](https://render.com).
2. **New** → **Web Service**.
3. Connect repo, set **Root Directory** to `SMART-GTM-AGENT/backend` (or the folder that has `main.py`).
4. **Build**: `pip install -r requirements.txt` (or use Docker).
5. **Start**: `uvicorn main:app --host 0.0.0.0 --port $PORT`.
6. Add **Postgres** (Render Postgres) in the same account and copy **Internal Database URL** into env.
7. **Environment**:
   - `OPENAI_API_KEY`
   - `DATABASE_URL` = Postgres URL from step 6
   - `MOCK_MODE` = `0` or `1`
8. Deploy and copy the service URL (e.g. `https://your-app.onrender.com`).

### Backend with Docker (any platform)

From repo root:

```bash
cd SMART-GTM-AGENT/backend
docker build -t smart-gtm-backend .
docker run -p 8000:8000 -e OPENAI_API_KEY=sk-... -e DATABASE_URL=postgresql://... smart-gtm-backend
```

Use the same env vars (`OPENAI_API_KEY`, `DATABASE_URL`, optional `MOCK_MODE`) in your cloud UI.

---

## 2. Database (Postgres)

- **Railway / Render**: Add Postgres in the same project; they give you `DATABASE_URL`. No extra steps.
- **Supabase**: Create a project, get **Connection string (URI)** from Settings → Database, set as `DATABASE_URL` in the backend service.

Format: a standard **Postgres connection URI** (your host’s dashboard shows the full string; do not commit it to git).

The app creates tables on startup (`Base.metadata.create_all`).

---

## 3. Frontend (Vercel)

1. Sign up at [vercel.com](https://vercel.com) and import your Git repo.
2. **Root Directory**: set to `SMART-GTM-AGENT/frontend` (or the folder that has `package.json`).
3. **Build**:
   - Build command: `npm run build`
   - Output: `dist` (Vite default).
4. **Environment** (important):
   - `VITE_API_URL` = your **backend URL** (e.g. `https://your-app.up.railway.app` or `https://your-app.onrender.com`).  
   No trailing slash. This is baked in at build time.
5. Deploy. Your app will call the backend at `VITE_API_URL`.

---

## 4. Environment variables summary

### Backend (Railway / Render / Docker)

| Variable          | Required | Example / notes |
|-------------------|----------|-----------------|
| `OPENAI_API_KEY` | Yes*     | `sk-proj-...` (*unless `MOCK_MODE=1`) |
| `DATABASE_URL`   | Yes      | Postgres URI from your host (user, host, db name) |
| `MOCK_MODE`      | No       | `1` = mock plans, no OpenAI; `0` or unset = use OpenAI |
| `PORT`           | No       | Set by Railway/Render; default 8000 in Docker |

### Frontend (Vercel)

| Variable        | Required | Example |
|-----------------|----------|---------|
| `VITE_API_URL`  | Yes      | `https://your-backend.up.railway.app` |

---

## 5. Alternative: single cloud

- **Google Cloud Run**: Run the backend container, use **Cloud SQL (Postgres)** and **Secret Manager** for `OPENAI_API_KEY`. Frontend can be Cloud Storage + Load Balancer or Firebase Hosting.
- **AWS**: **Amplify** for frontend, **App Runner** or **ECS** for backend, **RDS** or **Aurora** for Postgres, **Secrets Manager** for the API key.
- **Azure**: **App Service** for backend, **Azure Database for PostgreSQL**, **Key Vault** for secrets; **Static Web Apps** for frontend.

The “best” for this project in terms of simplicity and free tier is **Vercel (frontend) + Railway or Render (backend + Postgres)**. Use the table and env sections above to configure each service.
