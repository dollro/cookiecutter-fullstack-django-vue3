# Cookiecutter project template for Fullstack Django Vite/Vue3 Development

This cookiecutter was initially derived from https://github.com/cookiecutter/cookiecutter-django but enhanced with specific needs for modern fullstack development. It provides a production-ready template for building web applications with Django backend and Vue.js frontend.

> **Additional Documentation:**
> - [TECHSTACK-backend.md](TECHSTACK-backend.md) - Django-specific details (project structure, Celery, URL routing)
> - [TECHSTACK-frontend.md](TECHSTACK-frontend.md) - Vue.js-specific details (components, API module, Pinia)

---

## Table of Contents

1. [Stack Overview](#1-stack-overview)
2. [Development Environment](#2-development-environment)
3. [Docker Architecture](#3-docker-architecture)
4. [Frontend-Backend Integration](#4-frontend-backend-integration)
5. [CI/CD Pipeline](#5-cicd-pipeline)
6. [Multi-Platform Builds](#6-multi-platform-builds)
7. [Deployment](#7-deployment)
8. [Development Workflows](#8-development-workflows)
9. [Key Configuration Files](#9-key-configuration-files)

**Deep Dive Sections:**

10. [CI/CD Latest Tag Management](#10-deep-dive-cicd-latest-tag-management)
11. [E2C ARM Build Management](#11-deep-dive-e2c-arm-build-management)
12. [Production Docker Multi-Stage Build](#12-deep-dive-production-docker-multi-stage-build)
13. [Alternative Local Development (Virtual Environment)](#13-deep-dive-alternative-local-development-virtual-environment)
14. [Security Considerations](#14-deep-dive-security-considerations)

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
| **Backend** | Redis | 7.4 (local) / 5.0 (production) | Cache & message broker |
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
docker compose -f local.yml run --rm django python backend_django/manage.py <command>

# Examples
docker compose -f local.yml run --rm django python backend_django/manage.py makemigrations
docker compose -f local.yml run --rm django python backend_django/manage.py migrate
docker compose -f local.yml run --rm django python backend_django/manage.py shell
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
- Uses `uv` with `pyproject.toml` for dependency management (replaces pip + requirements.txt)
- Includes system dependencies as needed (e.g., TeX Live for PDF generation)

**Production:**
- Multi-stage build:
  1. `pre-stage`: Builds Vue.js assets with Node
  2. `main-stage`: Python environment with pre-built assets
- Frontend assets baked into Django static files

---

## 4. Frontend-Backend Integration

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
# backend_django/config/settings/base.py
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

## 5. CI/CD Pipeline

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

## 6. Multi-Platform Builds

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

## 7. Deployment

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

## 8. Development Workflows

### Database Migrations

```bash
# Create migration
docker compose -f local.yml run --rm django python backend_django/manage.py makemigrations

# Apply migrations
docker compose -f local.yml run --rm django python backend_django/manage.py migrate

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

## 9. Key Configuration Files

### Environment Files

```
.envs/
├── .local/
│   └── .django         # Local Docker development
├── .local-venv/
│   └── .django         # Local virtual environment development
├── .production/
│   └── .django         # Production settings
└── .test/
    └── .django         # Test settings
```

### Key Environment Variables

```bash
# Django
DJANGO_SETTINGS_MODULE=backend_django.config.settings.local
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

### Docker Directory Structure

```
docker/
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
docker compose -f local.yml run --rm django python backend_django/manage.py shell  # Django shell
docker compose -f local.yml logs celeryworker      # Check Celery
```

---

## 10. Deep Dive: CI/CD Latest Tag Management

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

## 11. Deep Dive: E2C ARM Build Management

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

## 12. Deep Dive: Production Docker Multi-Stage Build

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
# - Install Python dependencies via uv from pyproject.toml
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
# backend_django/config/settings/base.py reads version
version_file = ROOT_DIR / "VERSION.txt"
if version_file.exists():
    APP_VERSION = open(version_file).read().strip()
```

---

## 13. Deep Dive: Alternative Local Development (Virtual Environment)

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

## 14. Deep Dive: Security Considerations

### Authentication Security

| Layer | Implementation | Notes |
|-------|----------------|-------|
| **Password Storage** | Argon2 hashing | Django default (most secure) |
| **Token Type** | DRF TokenAuthentication | Simple, stateless tokens |
| **Token Storage** | localStorage | XSS vulnerable but standard |
| **Session** | Not used | Token-based instead |

### CSRF Protection

```python
# backend_django/config/settings/base.py
CSRF_COOKIE_SECURE = True       # HTTPS only
CSRF_COOKIE_HTTPONLY = False    # Accessible by JS (for axios)
CSRF_COOKIE_SAMESITE = "None"   # Cross-origin support
```

**Note:** CSRF is configured but currently relies primarily on token authentication.

### CORS Configuration

```python
# backend_django/config/settings/base.py
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
docker compose -f local.yml exec django bash                                        # Shell into Django
docker compose -f local.yml run --rm django python backend_django/manage.py shell  # Django shell
docker compose -f local.yml logs celeryworker                                       # Check Celery
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
