# ---------- Stage 1: build ----------
# Installs dependencies into a virtual environment. Build tools (gcc, etc.)
# stay in this stage and never reach the final image.
FROM python:3.12-slim AS builder

WORKDIR /app

# Prevents Python from writing .pyc files / buffering stdout (cleaner logs)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---------- Stage 2: final runtime image ----------
FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    DJANGO_SETTINGS_MODULE=core.settings.production

# Bring in the pre-built virtual environment (no compilers in this layer)
COPY --from=builder /opt/venv /opt/venv

# Create a non-root user to run the app (container security best practice).
# --home + mkdir ensures HOME isn't /nonexistent, which gunicorn's control
# server needs to write to (otherwise you'll see a harmless-but-noisy
# "Permission denied: /nonexistent" log line on every boot).
RUN addgroup --system django \
    && adduser --system --ingroup django --home /home/django --shell /usr/sbin/nologin django \
    && mkdir -p /home/django \
    && chown django:django /home/django
ENV HOME=/home/django

COPY . .

# Collect static files at build time so the running container never needs to
# (requires DJANGO_ALLOWED_HOSTS/SECRET_KEY to have *some* value; dummy is fine
# here since collectstatic doesn't need real secrets, just a working settings import)
RUN DJANGO_ALLOWED_HOSTS=build DJANGO_SECRET_KEY=build-only python manage.py collectstatic --noinput

RUN chown -R django:django /app
ENV HOME=/app
USER django

EXPOSE 8000

# Basic container-level health check (ECS will also do its own, see task-definition.json)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')" || exit 1

# gunicorn: production WSGI server. 3 workers is a safe default for a t3.micro-class
# task; tune via WEB_CONCURRENCY env var later if needed.
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
