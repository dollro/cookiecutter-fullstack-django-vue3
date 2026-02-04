# Cookiecutter Fullstack Django + Vue 3 / Vite

A production-ready [Cookiecutter](https://github.com/cookiecutter/cookiecutter) template for building modern fullstack web applications with **Django REST Framework** backend and **Vue.js 3** frontend.

Originally derived from [cookiecutter-django](https://github.com/cookiecutter/cookiecutter-django), this template has been enhanced for modern fullstack development with containerized workflows, async task processing, and CI/CD pipelines.

---

## Executive Summary

### Core Stack

| Layer | Technologies |
|-------|-------------|
| **Backend** | Django 5.0, Django REST Framework 3.16, PostgreSQL 17, Celery 5.5, Redis 7.4 |
| **Frontend** | Vue.js 3, Vite 5, Tailwind CSS 4, Pinia 2.1 |
| **DevOps** | Docker, Docker Compose v2, GitLab CI/CD, Multi-platform builds (amd64/arm64) |

### Key Features

- **Docker-First Development** - Fully containerized local development with hot-reload
- **Modern Frontend** - Vue 3 Composition API with Vite HMR and Tailwind CSS
- **REST API** - Token-based authentication with dj-rest-auth
- **Async Processing** - Celery workers with Redis broker and Flower monitoring
- **Production Ready** - Multi-stage Docker builds, Traefik reverse proxy, Gunicorn
- **CI/CD Pipeline** - GitLab CI with lint, test, multi-platform build, and release stages
- **Multi-Architecture** - Supports linux/amd64 and linux/arm64 builds

---

## Quick Start

### Prerequisites

- [Cookiecutter](https://cookiecutter.readthedocs.io/) (`pip install cookiecutter`)
- Docker & Docker Compose v2
- Make
- Git

### 1. Generate Your Project

```bash
# From the template repository
cookiecutter https://github.com/dollro/cookiecutter-fullstack-django-vue3

# Or from a local clone
cookiecutter /path/to/cookiecutter-fullstack-django-vue3
```

You will be prompted for:

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Human-readable project name | WebApp |
| `project_slug` | Python package name (auto-generated) | webapp |
| `description` | Project description | My awesome fullstack project... |
| `author_name` | Your name | John Doe |
| `domain_name` | Production domain | example.com |
| `email` | Contact email (auto-generated) | john.doe@example.com |
| `docker_registry` | Docker registry URL | registry.hub.docker.com:5000/webapp |
| `version` | Initial version | 0.1.0 |

### 2. Build & Run

```bash
cd your_project_slug

# Build Docker images
make local_docker_build

# Start all services
make local_docker_up

# Run database migrations
make local_docker_update

# Create admin user
make local_docker_createsuperuser
```

### 3. Access Your Application

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | Vue.js dev server with HMR |
| **Backend API** | http://localhost:8000 | Django REST API |
| **Django Admin** | http://localhost:8000/admin | Admin interface |
| **Flower** | http://localhost:5555 | Celery task monitoring |
| **Mailhog** | http://localhost:8025 | Email testing UI |

---

## Development Workflow

### Essential Commands

```bash
# Start/Stop
make local_docker_up          # Start all services
make local_docker_down        # Stop all services
make local_docker_build       # Rebuild images

# Database
make local_docker_update      # Run migrations
make local_docker_createsuperuser  # Create admin

# Django Management
docker compose -f local.yml run --rm django python backend_django/manage.py <command>
docker compose -f local.yml run --rm django python backend_django/manage.py shell
docker compose -f local.yml run --rm django pytest

# Logs
docker compose -f local.yml logs -f           # All services
docker compose -f local.yml logs django       # Django only
docker compose -f local.yml logs celeryworker # Celery only
```

### Before Committing

```bash
pre-commit run --all-files                           # Lint & format
docker compose -f local.yml run --rm django pytest   # Run tests
```

---

## Project Structure

After generation, your project will have:

```
your_project/
├── backend_django/          # Self-contained Django project
│   ├── config/              # Django project settings
│   │   ├── settings/        # Environment-specific settings
│   │   │   ├── base.py      # Shared settings
│   │   │   ├── local.py     # Development
│   │   │   ├── production.py # Production
│   │   │   └── test.py      # Testing
│   │   ├── celery_app.py    # Celery configuration
│   │   └── urls.py          # URL routing
│   ├── api/                 # REST API (views, serializers, urls)
│   ├── users/               # User management app
│   │   ├── api/             # User API endpoints
│   │   └── models.py        # Custom User model
│   ├── site_config/         # Site configuration app (SetupFlag model)
│   ├── requirements/        # DEPRECATED - kept for backwards compatibility
│   ├── fixtures/            # Django fixtures
│   ├── manage.py            # Django management script
│   ├── models.py            # Database models
│   ├── tasks.py             # Celery tasks
│   ├── static/              # Static files (+ built Vue assets)
│   └── templates/           # Django templates
├── pyproject.toml           # Python dependencies & tool config (single source of truth)
├── frontend_vue/            # Self-contained Vue.js frontend
│   ├── src/
│   │   ├── components/      # Vue components
│   │   ├── stores/          # Pinia state management
│   │   └── rest/rest.js     # Centralized API module
│   ├── vite.config.js       # Vite configuration
│   ├── .prettierrc          # Prettier configuration
│   └── package.json
├── docker/                  # Docker configurations
│   ├── local/               # Development Dockerfiles
│   └── production/          # Production Dockerfiles
├── .envs/                   # Environment files (gitignored)
├── local.yml                # Docker Compose for development
├── production.yml           # Docker Compose for production
├── Makefile                 # Convenience commands
└── TECHSTACK.md             # Full technical documentation
```

---

## Architecture Overview

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
         ▼                    ▼                              ▼
┌─────────────────┐  ┌─────────────────┐         ┌─────────────────────┐
│   PostgreSQL    │  │     Redis       │         │    Celery Worker    │
│   (Database)    │  │  (Cache/Broker) │◀────────│   (Async Tasks)     │
│   :5432         │  │     :6379       │         │                     │
└─────────────────┘  └─────────────────┘         └─────────────────────┘
```

---

## CI/CD Pipeline

The template includes a complete GitLab CI/CD configuration:

| Stage | Description | Triggers |
|-------|-------------|----------|
| **lint** | Pre-commit hooks (Black, Pylint) | All branches |
| **test** | pytest in Docker | All branches |
| **build** | Multi-platform Docker images | staging, tags |
| **build_manifests** | Merge multi-arch manifests | staging, tags |
| **release** | Push to release registry | tags only |

### Release Workflow

```bash
# Alpha/Internal release (no 'latest' tag update)
git tag 1.0.0alpha
git push origin 1.0.0alpha

# Official release (updates 'latest' tag)
git tag -a 1.0.0 -m "Release v1.0.0"
git push origin 1.0.0
```

---

## Documentation

For comprehensive technical documentation, see [TECHSTACK.md]({{ cookiecutter.project_slug }}/TECHSTACK.md) in the generated project, which includes:

- Detailed stack overview with diagrams
- Docker architecture and configuration
- Backend patterns (Django, DRF, Celery)
- Frontend patterns (Vue 3, Pinia, Tailwind)
- CI/CD pipeline deep dives
- Security considerations
- Alternative local venv development

---

## License

This project is open source. See the LICENSE file for details.

---

**Template Version:** January 2026
