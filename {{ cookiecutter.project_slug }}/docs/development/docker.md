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
