from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from django.views import defaults as default_views

# from rest_framework.authtoken.views import obtain_auth_token


urlpatterns = [
    path("", include("backend_django.urls")),
    # Fruit demo
    # path("fruits/", include("fruit.urls", namespace="fruits")),
    # Django Admin, use {% url 'admin:index' %}
    path(settings.ADMIN_URL, admin.site.urls),
    # User management
    path("accounts/", include("allauth.urls")),
    # Your stuff: custom urls includes go he
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# API URLS
api_base = "api/v1/"
urlpatterns += [
    # API base url
    path(api_base, include("dj_rest_auth.urls")),
    path(api_base + "registration/", include("dj_rest_auth.registration.urls")),
    path(api_base, include("config.api_router")),
    path(api_base, include("backend_django.api.urls")),
    # DRF auth token
    # path("auth-token/", obtain_auth_token),
]

if settings.DEBUG:
    # This allows the error pages to be debugged during development, just visit
    # these url in browser to see how these error pages look like.
    urlpatterns += [
        path(
            "400/",
            default_views.bad_request,
            kwargs={"exception": Exception("Bad Request!")},
        ),
        path(
            "403/",
            default_views.permission_denied,
            kwargs={"exception": Exception("Permission Denied")},
        ),
        path(
            "404/",
            default_views.page_not_found,
            kwargs={"exception": Exception("Page not Found")},
        ),
        path("500/", default_views.server_error),
    ]
    if "debug_toolbar" in settings.INSTALLED_APPS:
        import debug_toolbar

        urlpatterns = [path("__debug__/", include(debug_toolbar.urls))] + urlpatterns
