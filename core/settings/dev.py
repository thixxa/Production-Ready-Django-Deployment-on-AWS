"""
Local development settings.
Run with: DJANGO_SETTINGS_MODULE=core.settings.dev python manage.py runserver
(manage.py already defaults to this file - see manage.py)
"""

from .base import *  # noqa

DEBUG = True
ALLOWED_HOSTS = ["*"]
