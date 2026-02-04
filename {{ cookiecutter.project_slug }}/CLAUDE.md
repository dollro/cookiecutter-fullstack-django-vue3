# CLAUDE.md — {{ cookiecutter.project_name }}

## Project Identity

**{{ cookiecutter.project_name }}** — a fullstack Django + Vue 3 web application.
Domain: `{{ cookiecutter.domain_name }}`

## Architecture

- **Backend:** Django 5 + Django REST Framework at `backend_django/`
- **Frontend:** Vue 3 + Vite + Tailwind CSS at `frontend_vue/`
- **Async:** Celery workers with Redis broker
- **Database:** PostgreSQL 17
- **API base URL:** `/api/v1/`

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
├── frontend_vue/                # Vue 3 frontend
│   ├── src/
│   │   ├── main.ts              # App entry point
│   │   ├── components/          # Vue components
│   │   ├── stores/              # Pinia state management
│   │   └── rest/rest.ts         # Axios API client
│   └── vite.config.ts           # Vite configuration
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

## Development Commands

### Docker workflow (primary)

```bash
make local_docker_build           # Build images + run migrations
make local_docker_up              # Start all services
make local_docker_update          # Run migrations
make local_docker_down            # Stop services
make local_docker_createsuperuser # Create admin user
make local_docker_preseed         # Load fixtures
```

### Local venv workflow (alternative)

```bash
make local_venv_install           # Full setup (system deps, venv, DB, migrations)
make local_venv_up                # Start Django + Vue dev servers
make local_venv_celery_start      # Start Celery (separate terminal)
```

### Testing and linting

```bash
docker compose -f local.yml run --rm django pytest    # Tests (Docker)
pytest                                                 # Tests (venv)
pre-commit run --all-files                             # Lint + format
```

### Documentation

```bash
make docs-serve                   # Serve MkDocs locally
```

## Backend Conventions

- **Settings:** split across `backend_django/config/settings/{base,local,production,test}.py`
- **API routes:** registered in `backend_django/config/api_router.py` and `backend_django/api/urls.py`, base URL `/api/v1/`
- **Auth:** django-allauth + dj-rest-auth, custom User model at `backend_django/users/`
- **Celery tasks:** `backend_django/tasks.py`, config at `backend_django/config/celery_app.py`
- **Tests:** pytest + factory_boy, fixtures auto-loaded from `backend_django/fixtures/`
- **Test settings:** `DJANGO_SETTINGS_MODULE = backend_django.config.settings.test`

## Frontend Conventions

- **Entry:** `frontend_vue/src/main.ts`
- **State management:** Pinia stores in `frontend_vue/src/stores/`
- **API client:** Axios at `frontend_vue/src/rest/rest.ts`
- **Build output:** `backend_django/static/vue/` (django-vite integration)
- **Dev server:** port 3000 with HMR

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
| `.gitlab-ci.yml` | CI/CD pipeline (lint, test, build, release) |
| `docs/` | Full technical documentation (MkDocs Material) |
