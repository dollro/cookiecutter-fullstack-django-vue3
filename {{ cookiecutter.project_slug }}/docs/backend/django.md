# Django Backend

## Project Structure

```
<project>/
├── backend_django/           # Main Django application
│   ├── models.py             # Database models
│   ├── tasks.py              # Celery task definitions
│   ├── api/
│   │   ├── views.py          # REST API endpoints
│   │   ├── serializers.py    # DRF serializers
│   │   └── urls.py           # API URL routing
│   ├── users/                # User management app
│   │   ├── models.py         # Custom User model
│   │   ├── admin.py          # User admin configuration
│   │   ├── forms.py          # User forms
│   │   ├── tasks.py          # User-related Celery tasks
│   │   ├── adapters.py       # AllAuth adapters
│   │   └── api/
│   │       ├── views.py      # User API ViewSet
│   │       └── serializers.py # User serializers
│   ├── site_config/          # Site configuration app
│   │   └── models.py         # SetupFlag model
│   ├── utils/                # Business logic utilities
│   ├── migrations/           # Database migrations
│   ├── media/                # User uploads
│   ├── static/               # Static files (includes built Vue assets)
│   ├── templates/            # Django templates
│   ├── config/               # Django project configuration
│   │   ├── settings/
│   │   │   ├── base.py       # Common settings
│   │   │   ├── local.py      # Development settings
│   │   │   ├── production.py # Production settings
│   │   │   └── test.py       # Test settings
│   │   ├── urls.py           # Root URL configuration
│   │   ├── api_router.py     # DRF router configuration
│   │   ├── celery_app.py     # Celery configuration
│   │   └── wsgi.py           # WSGI entry point
│   ├── fixtures/             # Database fixtures
│   └── manage.py             # Django management script
├── pyproject.toml              # Python dependencies & tool config (single source of truth)
├── frontend_vue/               # Vue.js frontend application
└── docker/                     # Docker configuration files
```

## Settings Hierarchy

```
backend_django/config/settings/
├── base.py        # Shared settings (loaded by all environments)
├── local.py       # extends base.py → DEBUG=True, dev tools
├── production.py  # extends base.py → security, performance
└── test.py        # extends base.py → test configuration
```

Environment determined by `DJANGO_SETTINGS_MODULE`:

- Local: `backend_django.config.settings.local`
- Production: `backend_django.config.settings.production`

## Authentication System

- **django-allauth headless** for authentication (native REST API)
- Session token authentication via `X-Session-Token` header
- Email as primary identifier (no username required)
- `HEADLESS_ONLY = True` — no traditional HTML auth views

```python
# REST Framework configuration
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "allauth.headless.contrib.rest_framework.authentication.XSessionTokenAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
}
```

## Database

- PostgreSQL with `psycopg` 3.x driver
- Atomic requests enabled by default
- Custom User model recommended

## API Endpoint Patterns

```
Authentication (allauth headless):
POST   /_allauth/app/v1/auth/login      # Login
DELETE /_allauth/app/v1/auth/session     # Logout
POST   /_allauth/app/v1/auth/signup     # Register
GET    /_allauth/app/v1/auth/session     # Get current session

Feature Endpoints (example patterns):
POST   /api/v1/<feature>/create/        # Create resource
GET    /api/v1/<feature>/status/<id>/   # Check status
GET    /api/v1/<feature>/results/<id>/  # Get results
GET    /api/v1/<feature>/list/          # Paginated list
DELETE /api/v1/<feature>/delete/<id>/   # Delete resource

System:
GET    /api/v1/version-info/            # App version & environment
```

## URL Routing Architecture

### URL Configuration Hierarchy

```
backend_django/config/urls.py (Root)
├── ""                    → backend_django.urls (frontend views)
├── "admin/"              → Django Admin
├── "accounts/"           → allauth.urls (OAuth callbacks)
├── "_allauth/"           → allauth.headless.urls (auth API)
│   └── app/v1/auth/
│       ├── login         (POST)
│       ├── signup        (POST)
│       ├── session       (GET, DELETE)
│       └── password/     (request, reset, change)
│
└── API URLs (api/v1/):
    ├── ""                → backend_django.config.api_router (DRF routers)
    │
    └── ""                → backend_django.api.urls
        ├── <feature>/create/
        ├── <feature>/status/<id>/
        ├── <feature>/results/<id>/
        ├── <feature>/list/
        ├── <feature>/download-*/
        └── version/
```

### Trailing Slash Flexibility

All API endpoints accept both formats using `re_path` with optional trailing slash:

```python
re_path(r"^<feature>/create/?$", views.create_resource)
#                          ^^^ Optional trailing slash
```
