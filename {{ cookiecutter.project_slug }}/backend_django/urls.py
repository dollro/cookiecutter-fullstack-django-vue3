from django.urls import path, include
from django.views.generic import TemplateView


urlpatterns = [
    path("", TemplateView.as_view(template_name="home.html"), name="home"),
    path("test/", TemplateView.as_view(template_name="test.html"), name="test"),
    path("about/", TemplateView.as_view(template_name="about.html"), name="about"),
    path("users/", include("backend_django.users.urls", namespace="users")),
]
