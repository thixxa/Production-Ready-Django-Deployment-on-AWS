
FROM python:3.12-slim AS builder

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    DJANGO_SETTINGS_MODULE=core.settings.production

COPY --from=builder /opt/venv /opt/venv

RUN addgroup --system django \
    && adduser --system --ingroup django --home /home/django --shell /usr/sbin/nologin django \
    && mkdir -p /home/django \
    && chown django:django /home/django
ENV HOME=/home/django

COPY . .

RUN DJANGO_ALLOWED_HOSTS=build DJANGO_SECRET_KEY=build-only python manage.py collectstatic --noinput

RUN chown -R django:django /app
ENV HOME=/app
USER django

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')" || exit 1

CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]
