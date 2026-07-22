FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080
# Cloud Run, Render, and Fly.io all inject a $PORT env var (Cloud Run defaults
# to 8080) - shell form CMD lets ${PORT} expand, unlike the exec-array form.
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
