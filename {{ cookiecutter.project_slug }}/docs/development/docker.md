# Docker Architecture

## Local Development Stack (`local.yml`)

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

## Service Configuration

All services share a common network (`<project>_network`) enabling inter-container communication.

**Django Service:**

- Uses YAML anchor (`&django`) for configuration reuse by Celery services
- Mounts entire project directory for hot-reload: `.:/app:z`
- Environment loaded from `.envs/.local/.django`

**Node-Vue Service:**

- Separate `node_modules` volume to avoid conflicts
- Runs Vite dev server with HMR on port 3000

**Playwright Service (overlay — `test-e2e.yml`):**

- Defined in a **separate `test-e2e.yml` overlay**, not in `local.yml` — so it never starts with `docker compose up`
- Usage: `docker compose -f local.yml -f test-e2e.yml run --rm playwright` (or `make local_docker_vue_test_e2e`)
- Also works with CI: `docker compose -f test-ci.yml -f test-e2e.yml run --rm playwright`
- Adds a **Django healthcheck** so Playwright waits until Django is ready before running tests
- Uses `corepack` to install pnpm (no global npm install needed)
- Connects to Django at `http://django:5000` (correct internal port)
- Uses `ipc: host` and `init: true` (recommended by Playwright for Chromium stability)

## Docker Image Structure

**Local Development:**

- Images are built locally with source code mounted
- Uses `uv` with `pyproject.toml` for dependency management (replaces pip + requirements.txt)
- Includes system dependencies as needed (e.g., TeX Live for PDF generation)

**Production:**

- Multi-stage build:
  1. `pre-stage`: Builds Vue.js assets with Node
  2. `main-stage`: Python environment with pre-built assets
- Frontend assets baked into Django static files

See [Docker Production](../devops/docker-production.md) for production build details.
