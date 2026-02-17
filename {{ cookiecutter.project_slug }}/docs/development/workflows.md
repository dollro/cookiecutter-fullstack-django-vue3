# Development Workflows

## Database Migrations

```bash
# Create migration
docker compose -f local.yml run --rm django python backend_django/manage.py makemigrations

# Apply migrations
docker compose -f local.yml run --rm django python backend_django/manage.py migrate

# Or use shortcut
make local_docker_update
```

## Running Tests

### Backend Tests

```bash
# All tests
docker compose -f local.yml run --rm django pytest

# Specific file
docker compose -f local.yml run --rm django pytest backend_django/test/test_models.py

# With coverage
docker compose -f local.yml run --rm django pytest --cov=backend_django
```

### Frontend E2E Tests (Playwright)

```bash
# Run all E2E tests
pnpm --dir ./frontend_vue run test:e2e

# Run with interactive UI
pnpm --dir ./frontend_vue run test:e2e:ui

# Run against a custom base URL
E2E_BASE_URL=http://localhost:8000 pnpm --dir ./frontend_vue run test:e2e
```

E2E tests are configured in `frontend_vue/playwright.config.ts` and test files go in `frontend_vue/e2e/`. Tests run against Chromium, Firefox, and WebKit by default.

## Code Quality

```bash
# Run all pre-commit hooks (includes frontend-lint hook for ESLint)
pre-commit run --all-files

# Frontend linting (with auto-fix)
pnpm --dir ./frontend_vue run lint

# Frontend linting (check only, no fix — same as CI)
pnpm --dir ./frontend_vue run lint --no-fix

# TypeScript type checking
pnpm --dir ./frontend_vue run type-check
```

**Note:** The `frontend-lint` pre-commit hook runs ESLint on `frontend_vue/` files locally. In CI, this hook is skipped (`SKIP=frontend-lint`) because a dedicated `frontend_lint` CI job handles both type-checking and linting.

## Git Workflow

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

## Key Configuration Files

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
pre-commit run --all-files              # Lint/format check (includes frontend ESLint)
docker compose -f local.yml run --rm django pytest  # Run backend tests
pnpm --dir ./frontend_vue run type-check            # TypeScript type checking
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
