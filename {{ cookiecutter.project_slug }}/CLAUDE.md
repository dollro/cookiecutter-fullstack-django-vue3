# CLAUDE.md — {{ cookiecutter.project_name }}

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**{{ cookiecutter.project_name }}** — a fullstack Django + Vue 3 web application.
Domain: `{{ cookiecutter.domain_name }}`

## Architecture

- **Backend:** Django 5 + Django REST Framework at `backend_django/`
- **FastAPI:** Async API server at `fastapi_server/` (port 8001)
- **Frontend:** Vue 3 + Vite + Tailwind CSS at `frontend_vue/`
- **Async:** Celery workers with Redis broker
- **Database:** PostgreSQL 17
- **Django API base URL:** `/api/v1/`
- **FastAPI docs:** `http://localhost:8001/docs`

## Project Layout

```
├── backend_django/              # Django project
│   ├── config/                  # Settings, URLs, Celery, API router
│   │   ├── settings/            # base.py, local.py, production.py, test.py
│   │   ├── api_router.py        # DRF router
│   │   └── urls.py              # Root URL config
│   ├── api/                     # REST API views, serializers, urls
│   ├── users/                   # Custom User model + user API
│   ├── site_config/             # Site configuration app
│   ├── fixtures/                # Django fixtures (auto-loaded)
│   ├── models.py                # Database models
│   ├── tasks.py                 # Celery tasks
│   ├── static/                  # Static files (includes built Vue assets)
│   └── templates/               # Django templates
├── fastapi_server/              # FastAPI async server
│   ├── main.py                 # App factory + health checks
│   ├── config.py               # pydantic-settings configuration
│   └── routers/                # API route modules
├── frontend_vue/                # Vue 3 frontend
│   ├── src/
│   │   ├── main.ts              # App entry point
│   │   ├── components/          # Vue components
│   │   ├── stores/              # Pinia state management
│   │   └── rest/rest.ts         # Axios API client
│   ├── vite.config.ts           # Vite configuration
│   └── playwright.config.ts     # Playwright E2E test configuration
├── docker/                      # Dockerfiles (local + production)
├── docs/                        # MkDocs documentation
├── .envs/                       # Environment files (gitignored)
├── pyproject.toml               # Python config (single source of truth)
├── local.yml                    # Docker Compose dev
├── production.yml               # Docker Compose prod
├── Makefile                     # All build/run/deploy commands
├── .gitlab-ci.yml               # CI/CD pipeline
└── .pre-commit-config.yaml      # Pre-commit hooks
```

## Quick Start

> **Docker is the primary development environment.** All commands below use `docker compose -f local.yml`. See `docs/development/local-venv.md` for the venv alternative.

### Docker workflow (primary)

```bash
make local_docker_build           # Build images + run migrations
make local_docker_up              # Start all services
make local_docker_update          # Run migrations
make local_docker_down            # Stop services
make local_docker_createsuperuser # Create admin user
make local_docker_preseed         # Load fixtures
```

### Frontend commands (Docker)

```bash
make local_docker_vue_install     # Install / update frontend deps
make local_docker_vue_lint        # Run ESLint
make local_docker_vue_build       # Production build
```

> **All commands (Python and Node.js) must run inside Docker.** The local venv targets in the Makefile exist as a fallback but Docker is the canonical development environment.

### Local venv workflow (alternative)

```bash
make local_venv_install           # Full setup (system deps, venv, DB, migrations)
make local_venv_up                # Start Django + Vue dev servers
make local_venv_celery_start      # Start Celery (separate terminal)
```

### Testing and linting

All commands assume the Docker stack is running (`make local_docker_up`).

```bash
# Backend tests
docker compose -f local.yml run --rm django pytest

# Frontend type checking
docker compose -f local.yml exec node-vue pnpm run type-check

# Frontend lint (check only, no fix)
docker compose -f local.yml exec node-vue pnpm run lint --no-fix

# Playwright E2E tests (run from host — requires local Node/pnpm)
pnpm --dir ./frontend_vue run test:e2e

# Pre-commit hooks (run from host — requires pre-commit installed)
pre-commit run --all-files
```

### Documentation

```bash
make docs-serve                   # Serve MkDocs locally
```

## Cross-Component Notes

| Aspect | Backend (Django) | Backend (FastAPI) | Frontend |
|--------|------------------|-------------------|----------|
| Framework | Django 5, DRF 3.16 | FastAPI 0.115+ | Vue 3, Vite 5 |
| Language | Python 3.13 | Python 3.13 | TypeScript |
| Port | 8000 | 8001 | 3000 |
| Package Manager | uv (via pyproject.toml) | uv (shared pyproject.toml) | pnpm |
| Testing | pytest + factory_boy | pytest + pytest-asyncio | Vitest (unit), Playwright (E2E) |
| Build Tool | Docker | Docker | Vite |

**Important**:
- Always use `pnpm` for JavaScript dependencies, never npm or yarn.
- Python dependencies are managed via `pyproject.toml` (single source of truth).
- Always use `uv` for Python package management, never pip directly.

## Important: Code Organization Rules

- **Max file size**: Keep files under 600 lines. If a file grows beyond this, refactor into smaller modules.
- **Single responsibility**: Each module/file should do ONE thing well.
- **Function length**: Functions should not exceed 60 lines. Extract helpers.
- **Prefer composition**: Break complex logic into small, composable functions.
- **Index files for exports**: Use `index.ts` / `__init__.py` to re-export from module directories.

## Backend Conventions

- **Settings:** split across `backend_django/config/settings/{base,local,production,test}.py`
- **API routes:** registered in `backend_django/config/api_router.py` and `backend_django/api/urls.py`, base URL `/api/v1/`
- **Auth:** django-allauth headless (`X-Session-Token`), custom User model at `backend_django/users/`
- **Celery tasks:** `backend_django/tasks.py`, config at `backend_django/config/celery_app.py`
- **Tests:** pytest + factory_boy, fixtures auto-loaded from `backend_django/fixtures/`
- **Test settings:** `DJANGO_SETTINGS_MODULE = backend_django.config.settings.test`

## Frontend Conventions

- **Entry:** `frontend_vue/src/main.ts`
- **State management:** Pinia stores in `frontend_vue/src/stores/`
- **API client:** Axios at `frontend_vue/src/rest/rest.ts`
- **Build output:** `backend_django/static/vue/` (django-vite integration)
- **Dev server:** port 3000 with HMR
- **E2E tests:** Playwright at `frontend_vue/e2e/`, config at `frontend_vue/playwright.config.ts`
- **E2E base URL:** `E2E_BASE_URL` env var (defaults to `http://localhost:8000`)

## Code Style

- **Python:** Black (88 chars), Ruff, mypy — configured in `pyproject.toml`
- **Frontend:** Prettier, ESLint — configured in `frontend_vue/eslint.config.js`
- **Pre-commit:** `.pre-commit-config.yaml`
- **EditorConfig:** 4 spaces Python, 2 spaces HTML/CSS/JSON/YML, tabs Makefile

## Environment

- **Env files:** `.envs/` (gitignored)
- **Python deps:** `pyproject.toml` with extras `[dev]`, `[test]`, `[production]`, `[docs]`
- **Node deps:** `frontend_vue/package.json` (managed with pnpm)
- **Python package manager:** uv

## Key Files

| File | Purpose |
|------|---------|
| `Makefile` | All build/run/deploy commands |
| `local.yml` | Docker Compose dev config |
| `production.yml` | Docker Compose production config |
| `pyproject.toml` | Python deps + tool config (single source of truth) |
| `.gitlab-ci.yml` | CI/CD pipeline (lint, frontend_lint, test, build, release) |
| `docs/` | Full technical documentation (MkDocs Material) |

## Detailed Documentation

Architecture docs live in `docs/` (MkDocs). Run `make docs-serve` to browse locally.

- **Development guide**: `docs/development/`
- **Backend deep dives**: `docs/backend/`
- **Frontend deep dives**: `docs/frontend/`
- **DevOps & deployment**: `docs/devops/`
