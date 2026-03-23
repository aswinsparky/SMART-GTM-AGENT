# Smart GTM Agent - Backend (FastAPI)
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application code
COPY . .

# Default: run uvicorn (override PORT via env in cloud)
ENV PORT=8000
EXPOSE ${PORT}
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
