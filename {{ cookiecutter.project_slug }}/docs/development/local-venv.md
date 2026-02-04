# Alternative Local Development (Virtual Environment)

> **Note:** IMPORTANT: This is NOT the preferred development method. Docker-based development (see [Environment](environment.md)) is recommended. This alternative is maintained for situations where Docker is unavailable or impractical.

## Overview

The local venv setup runs services directly on the host machine using:

- Python virtual environment (`~/.virtualenvs/<project>`)
- System PostgreSQL (port 5432)
- System Redis (port 6379)
- Mailhog in Docker (only container used)
- Self-signed HTTPS certificates via mkcert

## Architecture Comparison

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

## Initial Setup

**Full Installation (one-time):**

```bash
make local_venv_install
```

This runs four sub-targets in sequence:

1. **`local_venv_sw_setup`** - System software installation
2. **`local_venv_db_setup`** - PostgreSQL database creation
3. **`local_venv_db_migrate`** - Django migrations
4. **`local_venv_db_preseed`** - Load fixtures

## Running Services

**Start Everything (Django + Vue + Mailhog):**

```bash
make local_venv_up    # or shortcut: make lvu
```

**Start Individual Services:**

```bash
make local_venv_django_run  # or shortcut: make lvd (Django only)
make local_venv_vue_run     # or shortcut: make lvv (Vue only)
```

## Access Points (Local Venv Mode)

| Service | URL | Notes |
|---------|-----|-------|
| **Django** | https://127.0.0.1:8000 | HTTPS with self-signed cert |
| **Vue** | http://localhost:3000 | Same as Docker mode |
| **Mailhog** | http://localhost:8025 | Same as Docker mode |
| **PostgreSQL** | localhost:5432 | System service |
| **Redis** | localhost:6379 | System service |

## When to Use Local Venv

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
