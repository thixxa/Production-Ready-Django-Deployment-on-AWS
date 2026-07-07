from django.http import JsonResponse
from django.shortcuts import render


def home(request):
    """Homepage - shown when someone visits the site."""
    return render(request, "portfolio/home.html")


def health_check(request):
    """
    Health check endpoint.
    ECS/Fargate calls this repeatedly to know if the container is healthy.
    It returns 200 fast, with no database/auth dependency, so a slow DB
    never causes the whole service to be killed and restarted.
    """
    return JsonResponse({"status": "healthy"})
