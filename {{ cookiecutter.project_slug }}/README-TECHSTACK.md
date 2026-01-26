# Cookiecutter project template for Fullstack Django Vite/Vue3 Development

This cookiecutter was initially derived from https://github.com/cookiecutter/cookiecutter-django but enhanced with specific needs for modern fullstack development. It provides a production-ready template for building web applications with Django backend and Vue.js frontend.

---

## Table of Contents

1. [Stack Overview](#1-stack-overview)
2. [Development Environment](#2-development-environment)
3. [Docker Architecture](#3-docker-architecture)
4. [Backend (Django)](#4-backend-django)
5. [Frontend (Vue.js)](#5-frontend-vuejs)
6. [Frontend-Backend Integration](#6-frontend-backend-integration)
7. [Async Processing (Celery)](#7-async-processing-celery)
8. [CI/CD Pipeline](#8-cicd-pipeline)
9. [Multi-Platform Builds](#9-multi-platform-builds)
10. [Deployment](#10-deployment)
11. [Development Workflows](#11-development-workflows)
12. [Key Configuration Files](#12-key-configuration-files)

**Deep Dive Sections:**

13. [Container Startup Process](#13-deep-dive-container-startup-process)
14. [CI/CD Latest Tag Management](#14-deep-dive-cicd-latest-tag-management)
15. [E2C ARM Build Management](#15-deep-dive-e2c-arm-build-management)
16. [Celery Task Processing](#16-deep-dive-celery-task-processing)
17. [Centralized API Module](#17-deep-dive-centralized-api-module)
18. [Production Docker Multi-Stage Build](#18-deep-dive-production-docker-multi-stage-build)
19. [URL Routing Architecture](#19-deep-dive-url-routing-architecture)
20. [Alternative Local Development (Virtual Environment)](#20-deep-dive-alternative-local-development-virtual-environment)
21. [Frontend Component Architecture](#21-deep-dive-frontend-component-architecture)
22. [Pinia State Management](#22-deep-dive-pinia-state-management)
23. [Security Considerations](#23-deep-dive-security-considerations)

---

## 1. Stack Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENT BROWSER                                 │
│                     (Vue.js SPA @ localhost:3000)                       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ REST API (JSON)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         DJANGO REST API                                  │
│                        (@ localhost:8000)                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Views     │  │ Serializers │  │   Models    │  │    Tasks    │    │
│  │  (DRF)      │  │   (DRF)     │  │  (ORM)      │  │  (Celery)   │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
         │                    │                              │
         │                    │                              │
         ▼                    ▼                              ▼
┌─────────────────┐  ┌─────────────────┐         ┌─────────────────────┐
│   PostgreSQL    │  │     Redis       │         │    Celery Worker    │
│   (Database)    │  │  (Cache/Broker) │◄────────│   (Async Tasks)     │
│   :5432         │  │     :6379       │         │                     │
└─────────────────┘  └─────────────────┘         └─────────────────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────────┐
                                                 │   External APIs     │
                                                 │  (Third-party       │
                                                 │   integrations)     │
                                                 └─────────────────────┘
```

### Core Technologies

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Backend** | Django | 5.0 | Web framework |
| **Backend** | Django REST Framework | 3.16 | REST API |
| **Backend** | PostgreSQL | 17 | Database |
| **Backend** | Celery | 5.5.3 | Async task queue |
| **Backend** | Redis | 7.4 | Cache & message broker |
| **Backend** | uv | latest | Python package manager |
| **Frontend** | Vue.js | 3.x | UI framework |
| **Frontend** | Vite | 5.x | Build tool & dev server |
| **Frontend** | Tailwind CSS | 4.1.11 | Styling |
| **Frontend** | Pinia | 2.1.6 | State management |
| **Frontend** | pnpm | latest | Package manager |
| **DevOps** | Docker | 28 | Containerization |
| **DevOps** | Docker Compose | v2 | Container orchestration |
| **DevOps** | GitLab CI | - | CI/CD pipeline |

---

## 2. Development Environment

### Prerequisites

- Docker & Docker Compose (v2)
- Make (for convenience commands)
- Git

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd <project-name>

# Build Docker images
make local_docker_build

# Start all services
make local_docker_up
```

### Access Points

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | Vue.js dev server (HMR enabled) |
| **Backend API** | http://localhost:8000 | Django REST API |
| **Django Admin** | http://localhost:8000/admin | Admin interface |
| **Flower** | http://localhost:5555 | Celery task monitoring |
| **Mailhog** | http://localhost:8025 | Email testing UI |

### Essential Makefile Commands

```bash
make local_docker_up          # Start all services
make local_docker_down        # Stop all services
make local_docker_build       # Build/rebuild images
make local_docker_update      # Run migrations
make local_docker_createsuperuser  # Create admin user
```

### Running Django Commands

**IMPORTANT:** All Python/Django commands must run inside Docker:

```bash
# General pattern
docker compose -f local.yml run --rm django python manage.py <command>

# Examples
docker compose -f local.yml run --rm django python manage.py makemigrations
docker compose -f local.yml run --rm django python manage.py migrate
docker compose -f local.yml run --rm django python manage.py shell
docker compose -f local.yml run --rm django pytest
```

---

## 3. Docker Architecture

### Local Development Stack (`local.yml`)

```yaml
Services:
  django:        # Backend API (port 8000 → 5000 internal)
  postgres:      # PostgreSQL database (port 5432)
  redis:         # Cache & Celery broker (port 6379)
  celeryworker:  # Async task processor
  celerybeat:    # Scheduled tasks
  flower:        # Task monitoring UI (port 5555)
  node-vue:      # Vite dev server (port 3000)
  mailhog:       # Email testing (port 8025)
```

### Service Configuration

All services share a common network (`<project>_network`) enabling inter-container communication.

**Django Service:**
- Uses YAML anchor (`&django`) for configuration reuse by Celery services
- Mounts entire project directory for hot-reload: `.:/app:z`
- Environment loaded from `.envs/.local/.django`

**Node-Vue Service:**
- Separate `node_modules` volume to avoid conflicts
- Runs Vite dev server with HMR on port 3000

### Docker Image Structure

**Local Development:**
- Images are built locally with source code mounted
- Uses `uv` (Astral's fast Python package manager) instead of pip
- Includes system dependencies as needed (e.g., TeX Live for PDF generation)

**Production:**
- Multi-stage build:
  1. `pre-stage`: Builds Vue.js assets with Node
  2. `main-stage`: Python environment with pre-built assets
- Frontend assets baked into Django static files

---

## 4. Backend (Django)

### Project Structure

```
<project>/
├── backend_django/           # Main Django application
│   ├── models.py             # Database models
│   ├── tasks.py              # Celery task definitions
│   ├── api/
│   │   ├── views.py          # REST API endpoints
│   │   ├── serializers.py    # DRF serializers
│   │   └── urls.py           # API URL routing
│   ├── utils/                # Business logic utilities
│   ├── migrations/           # Database migrations
│   ├── media/                # User uploads
│   ├── static/               # Static files (includes built Vue assets)
│   └── templates/            # Django templates
├── config/                   # Django project configuration
│   ├── settings/
│   │   ├── base.py           # Common settings
│   │   ├── local.py          # Development settings
│   │   └── production.py     # Production settings
│   ├── urls.py               # Root URL configuration
│   ├── celery_app.py         # Celery configuration
│   └── wsgi.py               # WSGI entry point
├── requirements/
│   ├── base.txt              # Core dependencies
│   ├── local.txt             # Development dependencies
│   └── production.txt        # Production dependencies
└── manage.py
```

### Settings Hierarchy

```
config/settings/
├── base.py        # Shared settings (loaded by all environments)
├── local.py       # extends base.py → DEBUG=True, dev tools
└── production.py  # extends base.py → security, performance
```

Environment determined by `DJANGO_SETTINGS_MODULE`:
- Local: `config.settings.local`
- Production: `config.settings.production`

### Authentication System

- **dj-rest-auth** + **django-allauth** for authentication
- Token-based authentication (DRF TokenAuthentication)
- Email as primary identifier (no username required)

```python
# REST Framework configuration
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework.authentication.TokenAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
}
```

### Database

- PostgreSQL with `psycopg` 3.x driver
- Atomic requests enabled by default
- Custom User model recommended

### API Endpoint Patterns

```
Authentication:
POST   /api/v1/auth/login/              # Login
POST   /api/v1/auth/logout/             # Logout
POST   /api/v1/auth/registration/       # Register

Feature Endpoints (example patterns):
POST   /api/v1/<feature>/create/        # Create resource
GET    /api/v1/<feature>/status/<id>/   # Check status
GET    /api/v1/<feature>/results/<id>/  # Get results
GET    /api/v1/<feature>/list/          # Paginated list
DELETE /api/v1/<feature>/delete/<id>/   # Delete resource

System:
GET    /api/v1/version-info/            # App version & environment
```

---

## 5. Frontend (Vue.js)

### Project Structure

```
frontend_vue/
├── src/
│   ├── main.js               # Application entry point
│   ├── App.vue               # Root component
│   ├── components/           # Vue components
│   ├── rest/
│   │   └── rest.js           # Centralized API module (MANDATORY)
│   ├── stores/               # Pinia state management
│   └── locales/              # i18n translation files
├── index.html                # HTML template
├── vite.config.js            # Vite configuration
├── package.json              # Dependencies
└── eslint.config.js          # ESLint flat config
```

### Build Configuration

**Vite Configuration (`vite.config.js`):**

```javascript
export default defineConfig({
  build: {
    outDir: '../../backend_django/static/vue/',  // Output to Django static
    manifest: true,  // Generate manifest for Django
  },
  base: '/static/vue',  // Production asset path
  server: {
    host: '0.0.0.0',
    port: 3000,
    hmr: {
      host: 'localhost',
      port: 3000,
      protocol: 'ws',
    },
  },
  plugins: [
    vue(),
    VueI18nPlugin(),
    splitVendorChunkPlugin(),
    tailwindcss(),
  ],
});
```

### Critical Patterns

**1. API Module (MANDATORY)**

All API calls must go through `src/rest/rest.js`:

```javascript
// CORRECT
import api from '../rest/rest.js';
const response = await api.fetchData(params);

// WRONG - Never import axios directly
import axios from 'axios';  // DON'T DO THIS
```

**2. Styling (Tailwind CSS v4 Only)**

No custom CSS files or `<style>` blocks allowed:

```vue
<!-- CORRECT -->
<div class="flex items-center p-4 bg-white rounded-lg shadow-md">
  <button class="px-4 py-2 bg-blue-600 text-white rounded">Submit</button>
</div>
```

**3. Component Structure**

Use Vue 3 Composition API with `<script setup>`:

```vue
<script setup>
import { ref, onMounted } from 'vue';
import api from '../rest/rest.js';

const loading = ref(false);
const data = ref(null);

async function fetchData() {
  loading.value = true;
  try {
    const response = await api.getSomeData();
    data.value = response.data;
  } finally {
    loading.value = false;
  }
}

onMounted(fetchData);
</script>

<template>
  <div class="p-4">...</div>
</template>
```

---

## 6. Frontend-Backend Integration

### Development Flow

```
┌─────────────────────┐     ┌─────────────────────┐
│   Vite Dev Server   │     │   Django Server     │
│   localhost:3000    │────▶│   localhost:8000    │
│   (Vue.js + HMR)    │     │   (REST API)        │
└─────────────────────┘     └─────────────────────┘
```

- Frontend runs on Vite dev server (port 3000) with hot module replacement
- API requests proxied to Django (port 8000)
- CORS configured for cross-origin requests

### Production Flow

```
┌─────────────────────────────────────────────────┐
│                   Django                         │
│   ┌─────────────────────────────────────────┐   │
│   │  /static/vue/  (Pre-built Vue assets)   │   │
│   └─────────────────────────────────────────┘   │
│   ┌─────────────────────────────────────────┐   │
│   │  /api/v1/      (REST API endpoints)     │   │
│   └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

- Vue assets built into `backend_django/static/vue/`
- Django serves both static assets and API from same origin
- WhiteNoise middleware handles static file serving

### Django-Vite Integration

Django uses `django-vite` to integrate with Vite:

```python
# config/settings/base.py
DJANGO_VITE = {
    "default": {
        "dev_mode": env.bool("DJANGO_VITE_DEV_MODE", default=False),
        "dev_server_host": "localhost",
        "dev_server_port": 3000,
        "static_url_prefix": "vue",
        "manifest_path": APPS_DIR / "static" / "vue" / ".vite" / "manifest.json",
    }
}
```

- `dev_mode=True`: Uses Vite dev server
- `dev_mode=False`: Uses built manifest for asset resolution

---

## 7. Async Processing (Celery)

### Architecture

```
┌──────────────┐      ┌─────────────┐      ┌──────────────────┐
│ Django View  │─────▶│    Redis    │◀─────│  Celery Worker   │
│ (task.delay) │      │  (Broker)   │      │ (task execution) │
└──────────────┘      └─────────────┘      └──────────────────┘
                             │
                             │
                      ┌──────▼──────┐
                      │ Celery Beat │
                      │ (Scheduler) │
                      └─────────────┘
```

### Configuration

```python
# config/settings/base.py
CELERY_BROKER_URL = env("CELERY_BROKER_URL")  # redis://redis:6379/0
CELERY_RESULT_BACKEND = CELERY_BROKER_URL
CELERY_TASK_TIME_LIMIT = 60 * 60  # 1 hour max
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
```

### Task Pattern

```python
# backend_django/tasks.py
from celery import shared_task

@shared_task(bind=True)
def process_data_task(self, request_id):
    """Process data asynchronously."""
    # Long-running operations
    # External API calls
    # Heavy computations
```

### Status Flow

```
pending → processing → completed
                    ↘ failed
```

### Monitoring

- **Flower** (http://localhost:5555): Real-time task monitoring
- **Celery logs**: `docker compose -f local.yml logs celeryworker`

---

## 8. CI/CD Pipeline

### Pipeline Stages

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌───────────────┐    ┌─────────┐
│  lint   │───▶│  test   │───▶│  build  │───▶│build_manifests│───▶│ release │
└─────────┘    └─────────┘    └─────────┘    └───────────────┘    └─────────┘
```

### Stage Details

| Stage | Description | Triggers |
|-------|-------------|----------|
| **lint** | Pre-commit hooks (Black, Pylint) | All feature branches |
| **test** | pytest in Docker | All feature branches |
| **build** | Build Docker images (per platform) | staging, tags |
| **build_manifests** | Merge multi-arch manifests | staging, tags |
| **release** | Push to release registry | tags only |

### Branch Rules

| Branch Pattern | Stages Run |
|----------------|------------|
| `fix/*`, `feat/*`, `test/*`, `chore/*` | lint, test |
| `staging` | lint, test, build, build_manifests |
| Tags (e.g., `1.2.3`) | All stages including release |

### Tag Types and Release Strategy

- **Annotated tags** (`git tag -a 1.0.0 -m "Release"`): Official releases, updates `latest` tag
- **Lightweight tags** (`git tag 1.0.0alpha`): Internal/alpha releases, no `latest` update

```bash
# Official release
git tag -a 1.2.3 -m "Release v1.2.3"
git push origin 1.2.3

# Alpha release
git tag 1.2.3alpha
git push origin 1.2.3alpha
```

---

## 9. Multi-Platform Builds

### Supported Platforms

| Platform | Architecture | Build Enabled | Notes |
|----------|--------------|---------------|-------|
| `linux/amd64` | x86_64 | Default ON | Standard servers |
| `linux/arm64` | ARM 64-bit | Optional | Apple Silicon, ARM servers |
| `linux/arm/v7` | ARM 32-bit | Optional | Raspberry Pi |

### Build Process

**Docker Buildx Bake** is used for parallel multi-service builds:

```
docker-bake-production.hcl
├── postgres    (single-stage)
├── traefik     (single-stage)
├── watchtower  (single-stage)
└── django      (multi-stage)
    ├── pre-stage   (Node.js - Vue build)
    └── main-stage  (Python - Django)
```

### ARM Build Strategies

Two options for ARM builds:

1. **Local Cross-Compilation**: Uses QEMU emulation on amd64 runner
2. **E2C Remote Build**: Uses native ARM EC2 instances via AWS

```yaml
# .gitlab-ci.yml
E2C_USAGE: "false"  # true = use AWS ARM instances
E2C_INSTANCE_STRATEGY: "template"  # or "existing"
```

### Manifest Merging

After platform-specific builds, manifests are merged:

```bash
# Creates multi-arch manifest
docker buildx imagetools create \
  -t registry/image:1.0.0 \
  registry/image:1.0.0-amd64 \
  registry/image:1.0.0-arm64
```

---

## 10. Deployment

### Production Docker Stack

```yaml
# production.yml services
django:       # Gunicorn serving Django
postgres:     # PostgreSQL database
redis:        # Cache & Celery broker
celeryworker: # Async task processor
celerybeat:   # Scheduled tasks
traefik:      # Reverse proxy (port 80)
```

### Traefik Configuration

```
Internet → Traefik (:80) → Django (:5000)
                        ↳ SSL termination
                        ↳ Routing rules
```

### Deployment Commands

```bash
# Deploy to specific host
make deploy_docker_<hostname>

# Uses SSH context for remote Docker operations
docker context use <hostname>-remote
docker compose -f deploy.yml up -d
```

### Volume Mounts (Production)

```yaml
volumes:
  production_postgres_data: {}       # Database files
  production_postgres_data_backups: {}
  production_traefik: {}             # SSL certificates
  production_media: {}               # User uploads
```

---

## 11. Development Workflows

### Database Migrations

```bash
# Create migration
docker compose -f local.yml run --rm django python manage.py makemigrations

# Apply migrations
docker compose -f local.yml run --rm django python manage.py migrate

# Or use shortcut
make local_docker_update
```

### Running Tests

```bash
# All tests
docker compose -f local.yml run --rm django pytest

# Specific file
docker compose -f local.yml run --rm django pytest backend_django/test/test_models.py

# With coverage
docker compose -f local.yml run --rm django pytest --cov=backend_django
```

### Code Quality

```bash
# Run pre-commit hooks
pre-commit run --all-files

# Frontend linting
pnpm --dir ./frontend_vue run lint
```

### Git Workflow

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code |
| `staging` | Integration testing |
| `feat/*` | New features |
| `fix/*` | Bug fixes |
| `chore/*` | Maintenance |

Commit format:
```
<type>(<scope>): <subject>

Types: feat, fix, docs, style, refactor, test, chore
Example: feat(api): add template download endpoint
```

---

## 12. Key Configuration Files

### Environment Files

```
.envs/
├── .local/
│   └── .django         # Local development
└── .production/
    └── .django         # Production settings
```

### Key Environment Variables

```bash
# Django
DJANGO_SETTINGS_MODULE=config.settings.local
DJANGO_DEBUG=True
DATABASE_URL=postgres://user:pass@postgres:5432/db
CELERY_BROKER_URL=redis://redis:6379/0

# Frontend
DJANGO_VITE_DEV_MODE=True

# External Services (examples)
API_KEY_SERVICE_A=...
API_KEY_SERVICE_B=...
```

### Docker Files

| File | Purpose |
|------|---------|
| `local.yml` | Local development stack |
| `production.yml` | Production build template |
| `docker-bake-production.hcl` | Buildx multi-service configuration |
| `docker-bake-staging.hcl` | Staging build configuration |
| `docker-bake-test.hcl` | CI test build configuration |

### Compose Directory Structure

```
compose/
├── local/
│   ├── django/Dockerfile     # Dev Django image
│   └── node-vue/Dockerfile   # Dev Node image
└── production/
    ├── django/Dockerfile     # Prod Django (multi-stage)
    ├── postgres/Dockerfile   # PostgreSQL with backup scripts
    ├── traefik/Dockerfile    # Traefik reverse proxy
    └── watchtower/Dockerfile # Auto-update service
```

---

## Quick Reference Card

### Daily Development

```bash
make local_docker_up                    # Start stack
make local_docker_down                  # Stop stack
make local_docker_update                # Run migrations
docker compose -f local.yml logs -f     # View all logs
docker compose -f local.yml logs django # Django logs only
```

### Before Committing

```bash
pre-commit run --all-files              # Lint/format check
docker compose -f local.yml run --rm django pytest  # Run tests
```

### Debugging

```bash
docker compose -f local.yml exec django bash       # Shell into Django
docker compose -f local.yml run --rm django python manage.py shell  # Django shell
docker compose -f local.yml logs celeryworker      # Check Celery
```

---

## 13. Deep Dive: Container Startup Process

### Django Container Lifecycle

The Django container follows a specific startup sequence controlled by entrypoint and start scripts.

#### Entrypoint Script (`compose/production/django/entrypoint`)

The entrypoint runs BEFORE the main command and handles:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTRYPOINT EXECUTION                          │
├─────────────────────────────────────────────────────────────────┤
│  1. Set CELERY_BROKER_URL from REDIS_URL                        │
│  2. Construct DATABASE_URL from individual components           │
│  3. Wait for PostgreSQL to be ready (connection test loop)      │
│  4. Runtime Vue environment variable injection                   │
│  5. Execute the actual command (/start or /start-celeryworker)  │
└─────────────────────────────────────────────────────────────────┘
```

**Runtime Vue Environment Injection:**

Build-time placeholders in Vue assets are replaced with actual runtime values:

```bash
# In entrypoint - replaces placeholders in built JS files
sed -i 's|VITE_APP_STATIC_ROOT_PLACEHOLDER|'${VITE_APP_STATIC_ROOT}'|g' $file
sed -i 's|VITE_APP_API_ROOT_PLACEHOLDER|'${VITE_APP_API_ROOT}'|g' $file
```

This allows the same Docker image to work in different environments with different API URLs.

#### Start Script (`compose/production/django/start`)

The start script runs the Django application:

```
┌─────────────────────────────────────────────────────────────────┐
│                      START SCRIPT FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│  1. Apply database migrations                                    │
│  2. Check SetupFlag model for initial setup status              │
│     ├── If not setup: Load fixtures (excluding dev_* files)    │
│     └── Mark setup as complete                                   │
│  3. Create/update superuser from environment variables          │
│  4. Run collectstatic (production only)                         │
│  5. Start Gunicorn on 0.0.0.0:5000                              │
└─────────────────────────────────────────────────────────────────┘
```

**One-Time Fixture Loading:**

```python
# Uses SetupFlag model to ensure fixtures only load once
from backend_django.config.models import SetupFlag
if not SetupFlag.objects.filter(setup_complete=True).exists():
    # Load fixtures
    SetupFlag.objects.create(setup_complete=True)
```

#### Local vs Production Differences

| Aspect | Local (`/start`) | Production (`/start`) |
|--------|------------------|----------------------|
| **Server** | `runserver_plus` (Werkzeug) | Gunicorn |
| **Migrations** | `makemigrations` + `migrate` | `migrate` only |
| **Fixtures** | All fixtures including `dev_*` | Excludes `dev_*` prefix |
| **Static files** | Not collected (Vite serves) | `collectstatic` run |

---

## 14. Deep Dive: CI/CD Latest Tag Management

### Automatic Latest Tag Updates (`ci_latest_manager.sh`)

The CI pipeline uses a sophisticated system to manage the `latest` Docker tag based on semantic versioning and tag types.

#### Decision Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                     SHOULD UPDATE LATEST?                               │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. Check UPDATE_LATEST_STRATEGY                                       │
│     ├── "force" → Always update latest                                 │
│     ├── "skip"  → Never update latest                                  │
│     └── "auto"  → Continue to step 2                                   │
│                                                                         │
│  2. Check tag type (annotated vs lightweight)                          │
│     ├── Annotated (git tag -a) → Continue to step 3                   │
│     └── Lightweight (git tag)  → Skip update (alpha/internal release) │
│                                                                         │
│  3. Compare versions against current registry latest                   │
│     ├── New version > Current latest → Update latest tag              │
│     └── New version <= Current latest → Keep existing latest          │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

#### Tag Type Detection Methods

The script uses multiple methods to detect tag type (in priority order):

1. **TAG_TYPE_OVERRIDE env var**: Manual override (`annotated` or `lightweight`)
2. **Git cat-file**: Check if tag object exists (`git cat-file -t refs/tags/$tag`)
3. **GitLab API**: Query tag metadata for message field
4. **Heuristic**: Tags containing `alpha/beta/rc/pre/dev/test` treated as lightweight

#### Version Comparison Against Registry

```bash
# Uses regctl to inspect current "latest" in the registry
./regctl image digest "$RELEASE_REGISTRY_IMAGE/<project>-django:latest"

# Compares against all version tags to find what "latest" points to
for tag in $version_tags; do
    tag_digest=$(./regctl image digest "$tag_image")
    if [ "$tag_digest" = "$latest_digest" ]; then
        # Found the version behind "latest"
    fi
done

# Semantic version comparison using sort -V
printf '%s\n' "$current" "$new" | sort -V | tail -n1
```

#### Release Workflow Examples

```bash
# Internal/Alpha Release (lightweight tag)
git tag 1.8.7alpha
git push origin 1.8.7alpha
# → Images built and pushed with 1.8.7alpha tag
# → 'latest' tag NOT updated

# Official Release (annotated tag)
git tag -a 1.8.7 -m "Release v1.8.7 - Features and fixes"
git push origin 1.8.7
# → Images built and pushed with 1.8.7 tag
# → 'latest' tag UPDATED (if 1.8.7 > current latest)
```

---

## 15. Deep Dive: E2C ARM Build Management

### E2C Instance Management (`ci_e2c_manager.sh`)

For native ARM builds (faster than QEMU emulation), the CI can spin up AWS EC2 ARM instances.

#### Two Instance Strategies

```
┌─────────────────────────────────────────────────────────────────────┐
│                    E2C INSTANCE STRATEGIES                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Strategy: "existing"                                                │
│  ├── Uses a pre-configured EC2 instance                             │
│  ├── Instance is stopped when idle, started for builds              │
│  ├── Requires: E2C_INSTANCE_ID                                      │
│  └── Lifecycle: Start → Build → Stop                                │
│                                                                      │
│  Strategy: "template"                                                │
│  ├── Creates fresh instance from launch template                    │
│  ├── Instance is terminated after build                             │
│  ├── Requires: E2C_LAUNCH_TEMPLATE_ID                               │
│  ├── Optional: Spot instances for cost savings                      │
│  └── Lifecycle: Create → Build → Terminate                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

#### E2C Lifecycle Commands

```bash
# Setup Phase (before_script in GitLab CI)
./ci_e2c_manager.sh setup
# → Determines strategy (existing/template)
# → Starts or creates instance
# → Waits for public IP assignment
# → Tests SSH connectivity
# → Copies project files to instance
# → Writes state file for later phases

# Build Phase (script in GitLab CI)
./ci_e2c_manager.sh build --platform="linux/arm64" --target="all" --bake-file="docker-bake-production.hcl"
# → Copies build script to remote instance
# → Executes docker buildx bake remotely
# → Pushes images to registry from ARM instance

# Cleanup Phase (after_script in GitLab CI)
./ci_e2c_manager.sh cleanup
# → Removes job-specific build directory

# Teardown Phase (after_script in GitLab CI)
./ci_e2c_manager.sh teardown
# → Stops (existing) or terminates (template) instance
# → Removes state file
```

#### State Persistence Across CI Phases

GitLab CI runs `before_script`, `script`, and `after_script` in separate shell sessions. State is persisted via file:

```bash
# State file format (.e2c_instance_state_${CI_JOB_ID})
TARGET_INSTANCE_ID=i-0123456789abcdef0
E2C_PUBLIC_IP=54.123.45.67
E2C_INSTANCE_STRATEGY=template
```

#### Required CI/CD Variables

```yaml
# AWS Credentials
AWS_ACCESS_KEY_ID: "..."
AWS_SECRET_ACCESS_KEY: "..."
AWS_DEFAULT_REGION: "eu-north-1"

# E2C Configuration
E2C_INSTANCE_STRATEGY: "template"
E2C_LAUNCH_TEMPLATE_ID: "lt-08c7ea1a2658e52f7"
E2C_SSH_USER: "admin"
E2C_SSH_PRIVATE_KEY: "base64-encoded-private-key"
E2C_BUILD_DIR: "~/builds"

# Optional for Spot Instances
E2C_USE_SPOT: "true"
E2C_SPOT_MAX_PRICE: "0.10"
```

---

## 16. Deep Dive: Celery Task Processing

### Task Execution Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                      ASYNC TASK PROCESSING FLOW                        │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  API View                                                              │
│    │                                                                   │
│    ├── Create Request object (status: "pending")                       │
│    ├── process_data_task.delay(request_id)  ←── Async dispatch        │
│    └── Return immediately with request ID                              │
│                                                                        │
│  Celery Worker                                                         │
│    │                                                                   │
│    ├── Fetch request from database                                     │
│    ├── Update status to "processing"                                   │
│    │                                                                   │
│    ├── PHASE 1: Input Validation                                       │
│    │   ├── Validate input data                                         │
│    │   ├── Normalize formats                                           │
│    │   └── Prepare working directory                                   │
│    │                                                                   │
│    ├── PHASE 2: Core Processing                                        │
│    │   ├── Execute business logic                                      │
│    │   ├── Call external APIs if needed                                │
│    │   └── Generate output data                                        │
│    │                                                                   │
│    ├── PHASE 3: Save Results                                           │
│    │   ├── Store results in database                                   │
│    │   └── Save output files if any                                    │
│    │                                                                   │
│    ├── PHASE 4: Cleanup                                                │
│    │   └── Remove temporary files/directories                          │
│    │                                                                   │
│    └── Update status to "completed" or "failed"                        │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
```

### Celery Configuration Details

```python
# config/celery_app.py
app = Celery("<project>")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()  # Auto-discovers tasks.py in all Django apps

# config/settings/base.py
CELERY_BROKER_URL = env("CELERY_BROKER_URL")      # Redis connection
CELERY_RESULT_BACKEND = CELERY_BROKER_URL         # Store results in Redis
CELERY_ACCEPT_CONTENT = ["json"]                   # JSON serialization only
CELERY_TASK_TIME_LIMIT = 60 * 60                   # 1 hour max per task
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
```

### Worker Start Command

```bash
# compose/local/django/celery/worker/start
celery -A config.celery_app worker -l INFO
```

### Task Implementation Pattern

```python
# backend_django/tasks.py
from celery import shared_task
from .models import ProcessingRequest, ProcessingResult

@shared_task(bind=True)
def process_data_task(self, request_id):
    """Process data asynchronously."""
    request = ProcessingRequest.objects.get(id=request_id)

    try:
        request.status = "processing"
        request.celery_task_id = self.request.id
        request.save()

        # Phase 1: Validate and prepare
        validated_data = validate_input(request)

        # Phase 2: Core processing
        result_data = execute_business_logic(validated_data)

        # Phase 3: Save results
        ProcessingResult.objects.create(
            request=request,
            data=result_data
        )

        request.status = "completed"
        request.save()

    except Exception as e:
        request.status = "failed"
        request.error_message = str(e)
        request.save()
        raise

    finally:
        # Phase 4: Cleanup
        cleanup_temporary_files(request)
```

### Status Polling Pattern (Frontend)

```javascript
// Poll for task completion
async function pollStatus(requestId) {
  const pollInterval = setInterval(async () => {
    const response = await api.getStatus(requestId);

    if (response.data.status === 'completed') {
      clearInterval(pollInterval);
      await fetchResults(requestId);
    } else if (response.data.status === 'failed') {
      clearInterval(pollInterval);
      showError(response.data.error_message);
    }
    // Continue polling for 'pending' or 'processing'
  }, 2000);  // Poll every 2 seconds
}
```

---

## 17. Deep Dive: Centralized API Module

### API Module Architecture (`frontend_vue/src/rest/rest.js`)

All frontend API communication is centralized in a single module.

```javascript
// Base configuration
axios.defaults.baseURL = import.meta.env.VITE_APP_API_ROOT

const api = axios.create({});

export default {
    // Authentication
    setAuthHeader(token) {
        api.defaults.headers.common['Authorization'] = 'Token ' + token
    },
    unsetAuthHeader() {
        api.defaults.headers.common['Authorization'] = ''
    },

    // API Methods...
}
```

### Authentication Pattern

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│    Login     │      │  Store Token │      │  Set Header  │
│   /login/    │─────▶│  (Pinia)     │─────▶│  api.setAuth │
└──────────────┘      └──────────────┘      └──────────────┘
                                                   │
                                                   ▼
                                            All subsequent
                                            requests include:
                                            Authorization: Token xyz
```

### Authenticated File Downloads

For file downloads requiring authentication, the API module uses blob responses:

```javascript
async downloadFile(resourceId) {
    const response = await api.get(`/resource/download/${resourceId}/`, {
        responseType: 'blob'  // Important: receive as binary
    });
    const filename = getFilenameFromResponse(response, `file_${resourceId}.pdf`);
    triggerBlobDownload(response.data, filename);
}

function triggerBlobDownload(blob, filename) {
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
}
```

### API Method Categories

| Category | Methods | Description |
|----------|---------|-------------|
| **Auth** | `login`, `logout`, `createUser`, `getUserData` | User authentication |
| **CRUD** | `create`, `read`, `update`, `delete` | Resource operations |
| **Processing** | `submitTask`, `getStatus`, `getResults` | Async task operations |
| **Downloads** | `downloadFile`, `downloadArchive` | Authenticated file downloads |

---

## 18. Deep Dive: Production Docker Multi-Stage Build

### Django Production Dockerfile Stages

```dockerfile
# STAGE 1: pre-stage (Node.js)
FROM node:18-bookworm-slim AS pre-stage
# - Install pnpm
# - Copy package.json and install dependencies
# - Copy entire project
# - Run: pnpm run build -- --mode production
# - Output: /app/backend_django/static/vue/

# STAGE 2: main-stage (Python)
FROM python:3.12-slim-bookworm AS main-stage
# - Install system dependencies
# - Install uv (Astral's package manager)
# - Install Python dependencies via uv
# - Copy from pre-stage: includes pre-built Vue assets
# - Setup non-root user
# - Copy start scripts
# - Write VERSION.txt
```

### Why Multi-Stage?

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BUILD SIZE COMPARISON                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Single Image (if we kept Node):                                    │
│  ├── Node.js runtime: ~300MB                                        │
│  ├── node_modules: ~500MB                                           │
│  ├── Python + packages: ~1.5GB                                      │
│  └── Total: ~2.3GB                                                  │
│                                                                      │
│  Multi-Stage (final image):                                         │
│  ├── Python + packages: ~1.5GB                                      │
│  ├── Built Vue assets: ~5MB                                         │
│  └── Total: ~1.5GB (35% smaller)                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Version Injection

```dockerfile
# Build arg passed from CI
ARG APP_VERSION=development

# Written to file for Django to read at startup
RUN echo "${APP_VERSION}" > /app/VERSION.txt
```

```python
# config/settings/base.py reads version
version_file = ROOT_DIR / "VERSION.txt"
if version_file.exists():
    APP_VERSION = open(version_file).read().strip()
```

---

## 19. Deep Dive: URL Routing Architecture

### URL Configuration Hierarchy

```
config/urls.py (Root)
├── ""                    → backend_django.urls (frontend views)
├── "admin/"              → Django Admin
├── "accounts/"           → allauth.urls (social auth)
│
└── API URLs (api/v1/):
    ├── ""                → dj_rest_auth.urls
    │   ├── login/
    │   ├── logout/
    │   ├── user/
    │   └── password/
    │
    ├── "registration/"   → dj_rest_auth.registration.urls
    │
    ├── ""                → config.api_router (DRF routers)
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

---

## 20. Deep Dive: Alternative Local Development (Virtual Environment)

> **Note:** IMPORTANT: This is NOT the preferred development method. Docker-based development (Section 2) is recommended. This alternative is maintained for situations where Docker is unavailable or impractical.

### Overview

The local venv setup runs services directly on the host machine using:
- Python virtual environment (`~/.virtualenvs/<project>`)
- System PostgreSQL (port 5432)
- System Redis (port 6379)
- Mailhog in Docker (only container used)
- Self-signed HTTPS certificates via mkcert

### Architecture Comparison

```text
┌─────────────────────────────────────────────────────────────────────────┐
│              Docker Development          │    Local Venv Development   │
├─────────────────────────────────────────────────────────────────────────┤
│  All services in Docker containers       │  Only Mailhog in Docker     │
│  Environment: .envs/.local/.django       │  Environment: .envs/.local-venv/.django │
│  Django: http://localhost:8000           │  Django: https://127.0.0.1:8000 (HTTPS!) │
│  PostgreSQL: Docker container            │  PostgreSQL: System service │
│  Redis: Docker container                 │  Redis: System service      │
│  Celery: Docker container                │  Celery: celeryd-venv.sh daemon │
│  Vue: Docker node-vue container          │  Vue: Direct pnpm process   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Initial Setup

**Full Installation (one-time):**

```bash
make local_venv_install
```

This runs four sub-targets in sequence:

1. **`local_venv_sw_setup`** - System software installation
2. **`local_venv_db_setup`** - PostgreSQL database creation
3. **`local_venv_db_migrate`** - Django migrations
4. **`local_venv_db_preseed`** - Load fixtures

### Running Services

**Start Everything (Django + Vue + Mailhog):**

```bash
make local_venv_up    # or shortcut: make lvu
```

**Start Individual Services:**

```bash
make local_venv_django_run  # or shortcut: make lvd (Django only)
make local_venv_vue_run     # or shortcut: make lvv (Vue only)
```

### Access Points (Local Venv Mode)

| Service | URL | Notes |
|---------|-----|-------|
| **Django** | https://127.0.0.1:8000 | HTTPS with self-signed cert |
| **Vue** | http://localhost:3000 | Same as Docker mode |
| **Mailhog** | http://localhost:8025 | Same as Docker mode |
| **PostgreSQL** | localhost:5432 | System service |
| **Redis** | localhost:6379 | System service |

### When to Use Local Venv

**Advantages:**
- Faster startup (no container overhead)
- Native debugging tools work directly
- Easier IDE integration
- Lower resource usage

**Disadvantages:**
- Requires system dependencies (PostgreSQL, Redis, Python)
- Less isolated (can conflict with other projects)
- Manual service management
- Harder to match production environment

---

## 21. Deep Dive: Frontend Component Architecture

### Component Hierarchy

```
frontend_vue/src/
├── main.js                    # Entry point - multi-mount pattern
├── Main.vue                   # Root component (minimal)
└── components/
    ├── AppContainer.vue       # App container with navigation
    │   ├── AuthForm.vue       # Authentication form
    │   ├── ListView.vue       # List/history view
    │   ├── FormView.vue       # Main feature form
    │   ├── DetailView.vue     # Detail view
    │   └── SettingsView.vue   # Settings/config management
    └── AppVersion.vue         # Version badge
```

### Multi-Mount Pattern

Unlike typical SPAs, this architecture mounts multiple Vue apps into different DOM elements:

```javascript
// main.js - Multi-mount strategy for Django integration
createAppInEl(Main, "#vue-main");
createAppInEl(AuthForm, "#vue-auth");
createAppInEl(FeatureForm, "#vue-feature");
createAppInEl(AppContainer, "#vue-app");
```

**Factory Function:**
```javascript
// create_app_utils.js
export const createAppInEl = (options, selector) => {
  const mountTarget = document.querySelector(selector);
  if (!mountTarget) return null;  // Safe skip if element missing

  const app = createApp(options);
  app.use(i18n);

  const pinia = createPinia();
  pinia.use(piniaPluginPersistedstate);
  app.use(pinia);

  app.mount(mountTarget);
  return app;
}
```

### Component Communication

**No Vue Router** - Uses component-based view switching:

```javascript
// AppContainer.vue
const currentView = ref('list')  // 'list' | 'form' | 'settings' | 'detail'
const selectedDetailId = ref(null)

function setView(view) {
  currentView.value = view
}

function viewDetail(resourceId) {
  selectedDetailId.value = resourceId
  currentView.value = 'detail'
}
```

### Key Components

#### AppContainer.vue (Container)

```
┌─────────────────────────────────────────────────────────────┐
│  Navigation Header                                           │
│  ┌─────────────┬────────────────┬─────────────┬───────────┐ │
│  │ Logo        │ List Tab       │ New Tab     │ Settings  │ │
│  └─────────────┴────────────────┴─────────────┴───────────┘ │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Dynamic View Area                                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  AuthForm    (when not authenticated)                   ││
│  │  ListView    (when currentView === 'list')              ││
│  │  FormView    (when currentView === 'form')              ││
│  │  DetailView  (when currentView === 'detail')            ││
│  │  SettingsView (when currentView === 'settings')         ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
├─────────────────────────────────────────────────────────────┤
│  Footer (AppVersion component)                               │
└─────────────────────────────────────────────────────────────┘
```

#### FormView.vue (Main Feature Form)

**Processing Flow:**
```
Submit Form → POST /api/create/ → Store request_id
                                      │
                                      ▼
              ┌──────────────────────────────────────┐
              │  Poll Loop (every 2 seconds)          │
              │  GET /status/{id}/ → check status     │
              │    ├─ pending → continue polling      │
              │    ├─ processing → continue polling   │
              │    ├─ completed → fetch results       │
              │    └─ failed → show error             │
              └──────────────────────────────────────┘
                                      │
                                      ▼
              GET /results/{id}/ → Display results
```

#### ListView.vue (History)

**Features:**
- Paginated list (configurable items per page)
- Status filtering (All / Pending / Completed / Failed)
- Card-based display with status badges
- Quick actions (View Details, Download)

**Card Structure:**
```
┌─────────────────────────────────────────────┐
│ [Completed] [Type Badge]                    │
│ Resource Title                              │
│ Description or URL                          │
│ Created: Jan 15, 2026                       │
├─────────────────────────────────────────────┤
│ [View Details]  [Download]                  │
└─────────────────────────────────────────────┘
```

---

## 22. Deep Dive: Pinia State Management

### Auth Store Architecture (`frontend_vue/src/stores/auth.js`)

```javascript
export const useAuthStore = defineStore('auth', () => {
  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════
  const user = ref(null)
  const token = ref(null)
  const isLoading = ref(false)
  const error = ref(null)

  // ═══════════════════════════════════════════════════════════
  // COMPUTED (Getters)
  // ═══════════════════════════════════════════════════════════
  const isAuthenticated = computed(() => !!token.value)
  const username = computed(() => user.value?.username || user.value?.email || '')

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  async function login(credentials) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.login(credentials)
      token.value = response.data.key  // Token from dj-rest-auth
      api.setAuthHeader(token.value)   // Set axios default header
      await fetchUser()
    } catch (err) {
      error.value = extractErrorMessage(err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function logout() {
    try {
      await api.logout()  // Optional - continue even if fails
    } catch {}
    token.value = null
    user.value = null
    api.unsetAuthHeader()
  }

  async function fetchUser() {
    const response = await api.getUserData()
    user.value = response.data
  }

  function initialize() {
    // Called on app mount - restores session from localStorage
    if (token.value) {
      api.setAuthHeader(token.value)
      fetchUser().catch(() => logout())  // Invalid token → logout
    }
  }

  return { user, token, isLoading, error, isAuthenticated, username,
           login, logout, fetchUser, initialize, clearError }
}, {
  // ═══════════════════════════════════════════════════════════
  // PERSISTENCE CONFIG
  // ═══════════════════════════════════════════════════════════
  persist: {
    key: 'auth',
    paths: ['token', 'user'],  // Only persist these fields
    afterRestore: (ctx) => {
      // Restore auth header after page reload
      if (ctx.store.token) {
        api.setAuthHeader(ctx.store.token)
      }
    }
  }
})
```

### Authentication Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION STATE FLOW                           │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  PAGE LOAD                                                             │
│    │                                                                   │
│    ▼                                                                   │
│  ┌───────────────────────────────────────┐                            │
│  │ Check localStorage for persisted auth  │                            │
│  └───────────────────────────────────────┘                            │
│    │                                                                   │
│    ├─── Token found ────────────────────┐                              │
│    │                                     ▼                              │
│    │                    ┌─────────────────────────────┐                │
│    │                    │ Set axios Authorization     │                │
│    │                    │ header: "Token {token}"     │                │
│    │                    └─────────────────────────────┘                │
│    │                                     │                              │
│    │                                     ▼                              │
│    │                    ┌─────────────────────────────┐                │
│    │                    │ GET /api/v1/user/           │                │
│    │                    │ Validate token is still     │                │
│    │                    │ valid                       │                │
│    │                    └─────────────────────────────┘                │
│    │                           │              │                        │
│    │                      Valid │          Invalid                     │
│    │                           ▼              ▼                        │
│    │                   ┌──────────┐    ┌──────────┐                   │
│    │                   │ Show App │    │  Logout  │                   │
│    │                   └──────────┘    └──────────┘                   │
│    │                                          │                        │
│    └─── No token ─────────────────────────────┼─────┐                 │
│                                               │     │                  │
│                                               ▼     ▼                  │
│                              ┌──────────────────────────────┐         │
│                              │  Show Login Form              │         │
│                              └──────────────────────────────┘         │
│                                               │                        │
│                                               ▼                        │
│  LOGIN                    ┌──────────────────────────────┐            │
│                           │ POST /api/v1/login/          │            │
│                           │ {username, password}         │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │ Response: {key: "token123"}  │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │ Store token in Pinia state   │            │
│                           │ Set axios header             │            │
│                           │ Persist to localStorage      │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │  Navigate to Main View       │            │
│                           └──────────────────────────────┘            │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
```

### LocalStorage Structure

```javascript
// Key: 'auth' (from persist config)
{
  "token": "abc123def456...",
  "user": {
    "pk": 1,
    "username": "john@example.com",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

### Error Handling

```javascript
function extractErrorMessage(err) {
  // Handle nested error structures from DRF
  const data = err.response?.data
  if (!data) return 'Network error'

  if (typeof data === 'string') return data
  if (data.detail) return data.detail
  if (data.non_field_errors) return data.non_field_errors[0]

  // Field-specific errors
  const firstKey = Object.keys(data)[0]
  return Array.isArray(data[firstKey]) ? data[firstKey][0] : data[firstKey]
}
```

---

## 23. Deep Dive: Security Considerations

### Authentication Security

| Layer | Implementation | Notes |
|-------|----------------|-------|
| **Password Storage** | Argon2 hashing | Django default (most secure) |
| **Token Type** | DRF TokenAuthentication | Simple, stateless tokens |
| **Token Storage** | localStorage | XSS vulnerable but standard |
| **Session** | Not used | Token-based instead |

### CSRF Protection

```python
# config/settings/base.py
CSRF_COOKIE_SECURE = True       # HTTPS only
CSRF_COOKIE_HTTPONLY = False    # Accessible by JS (for axios)
CSRF_COOKIE_SAMESITE = "None"   # Cross-origin support
```

**Note:** CSRF is configured but currently relies primarily on token authentication.

### CORS Configuration

```python
# config/settings/base.py
CORS_URLS_REGEX = r"^/api/.*$"    # Only API endpoints
CORS_ALLOW_CREDENTIALS = False    # No cookies needed (token auth)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",      # Vue dev server
    "http://localhost:8000",      # Django dev server
]
```

### Docker User Permissions

| Environment | UID:GID | User | Sudo Access |
|-------------|---------|------|-------------|
| **Local Dev** | 1000:1000 | django | Full (passwordless) |
| **Production** | 10000:10001 | django | None |

High UID in production prevents privilege escalation if container is compromised.

### File Upload Security

```python
# Files stored in private MEDIA_ROOT
MEDIA_ROOT = APPS_DIR / "media"  # Not publicly accessible

# Validate file extensions per upload type
# Implement in serializers/views
```

### Secret Management

| Secret | Storage | Access |
|--------|---------|--------|
| Django SECRET_KEY | `.envs/.production/.django` | Environment variable |
| External API Keys | `.envs/.production/.django` | Environment variable |
| Database Password | `.envs/.production/.django` | Environment variable |
| Registry Passwords | GitLab CI Variables | Masked in logs |

**Never Committed:**
- `.envs/` directory (gitignored)
- API keys
- Database credentials
- SSL certificates

### Network Security (Production)

```
┌─────────────────────────────────────────────────────────────────┐
│                     NETWORK ISOLATION                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  EXTERNAL (Internet)                                             │
│       │                                                          │
│       │ Port 80 only                                             │
│       ▼                                                          │
│  ┌─────────────┐                                                │
│  │   Traefik   │  ← TLS termination (Let's Encrypt)             │
│  │   (Proxy)   │  ← CSRF middleware                             │
│  └─────────────┘                                                │
│       │                                                          │
│       │ Internal network (<project>_network)                     │
│       ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  INTERNAL SERVICES                           ││
│  │  ┌─────────┐  ┌──────────┐  ┌───────────┐  ┌─────────────┐ ││
│  │  │ Django  │  │ Postgres │  │   Redis   │  │   Celery    │ ││
│  │  │ :5000   │  │  :5432   │  │   :6379   │  │  (workers)  │ ││
│  │  └─────────┘  └──────────┘  └───────────┘  └─────────────┘ ││
│  │       ↑           ↑              ↑               ↑          ││
│  │       └───────────┴──────────────┴───────────────┘          ││
│  │              No external port exposure                       ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Input Validation

**Backend (Django):**
- DRF serializers validate all API input
- File type validation by extension
- URL length limits
- Required field enforcement

**Frontend (Vue):**
- Form validation before submission
- File type filtering on input elements
- Optional field handling

### Rate Limiting

Consider implementing:
- django-ratelimit for API endpoints
- Celery task concurrency limits per user

---

## Quick Reference Card

### Daily Development

```bash
make local_docker_up                    # Start stack
make local_docker_down                  # Stop stack
make local_docker_update                # Run migrations
docker compose -f local.yml logs -f     # View all logs
docker compose -f local.yml logs django # Django logs only
```

### Before Committing

```bash
pre-commit run --all-files              # Lint/format check
docker compose -f local.yml run --rm django pytest  # Run tests
```

### Debugging

```bash
docker compose -f local.yml exec django bash       # Shell into Django
docker compose -f local.yml run --rm django python manage.py shell  # Django shell
docker compose -f local.yml logs celeryworker      # Check Celery
```

### Release Commands

```bash
# Alpha/Internal release (no latest update)
git tag 1.2.3alpha
git push origin 1.2.3alpha

# Official release (updates latest)
git tag -a 1.2.3 -m "Release v1.2.3"
git push origin 1.2.3
```

---

**Last Updated:** January 2026
