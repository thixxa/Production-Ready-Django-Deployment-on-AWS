"""
Production settings, used inside the Docker container on ECS.
Activated via: DJANGO_SETTINGS_MODULE=core.settings.production
"""

import os

from .base import *  # noqa

DEBUG = False

# Comma-separated list of hosts, e.g. "django-alb-123.eu-north-1.elb.amazonaws.com"
# Set as an environment variable / ECS task definition variable - never hardcode.
ALLOWED_HOSTS = [
    h.strip() for h in os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",") if h.strip()
]

# --- Security hardening (from the project's production checklist) ---
# NOTE: SSL/HSTS settings are only turned on once you put HTTPS in front of the
# ALB (Phase 5 - custom domain + ACM certificate). Turning these on before you
# have HTTPS will make the health check / HTTP-only ALB break the app, so they
# are gated behind an env var you'll flip to "true" later.
USE_HTTPS = os.environ.get("DJANGO_USE_HTTPS", "false").lower() == "true"

SECURE_SSL_REDIRECT = USE_HTTPS
SECURE_HSTS_SECONDS = 31536000 if USE_HTTPS else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = USE_HTTPS
SECURE_HSTS_PRELOAD = USE_HTTPS
SECURE_CONTENT_TYPE_NOSNIFF = True
CSRF_COOKIE_SECURE = USE_HTTPS
SESSION_COOKIE_SECURE = USE_HTTPS
X_FRAME_OPTIONS = "DENY"
