# Development Environment

## Prerequisites

- Docker & Docker Compose (v2)
- Make (for convenience commands)
- Git

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd <project-name>

# Build Docker images
make local_docker_build

# Start all services
make local_docker_up
```

## Access Points

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | Vue.js dev server (HMR enabled) |
| **Backend API** | http://localhost:8000 | Django REST API |
| **Django Admin** | http://localhost:8000/admin | Admin interface |
| **Flower** | http://localhost:5555 | Celery task monitoring |
| **Mailhog** | http://localhost:8025 | Email testing UI |

## Essential Makefile Commands

```bash
make local_docker_up          # Start all services
make local_docker_down        # Stop all services
make local_docker_build       # Build/rebuild images
make local_docker_update      # Run migrations
make local_docker_createsuperuser  # Create admin user
```

## Running Django Commands

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
