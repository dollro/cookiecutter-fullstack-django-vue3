# {{ cookiecutter.project_name }}

This cookiecutter was initially derived from https://github.com/cookiecutter/cookiecutter-django but enhanced with specific needs for modern fullstack development. It provides a production-ready template for building web applications with Django backend and Vue.js frontend.

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

## Core Technologies

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

## Documentation Guide

| Section | Description |
|---------|-------------|
| [Development > Environment](development/environment.md) | Prerequisites, quick start, access points |
| [Development > Docker](development/docker.md) | Docker architecture, local.yml services |
| [Development > Local Venv](development/local-venv.md) | Alternative venv-based development |
| [Development > Workflows](development/workflows.md) | Dev workflows, config files, Makefile reference |
| [Backend > Django](backend/django.md) | Project structure, settings, auth, API, URL routing |
| [Backend > Celery](backend/celery.md) | Celery architecture, task processing, container startup |
| [Frontend > Vue Structure](frontend/vue-structure.md) | Vue.js structure, Vite config, components, critical patterns |
| [Frontend > State & Auth](frontend/state-and-auth.md) | Pinia store, auth flow, API module |
| [DevOps > Integration](devops/integration.md) | Frontend-backend integration |
| [DevOps > CI/CD](devops/cicd.md) | CI/CD pipeline, multi-platform builds, tag management, ARM builds |
| [DevOps > Deployment](devops/deployment.md) | Production deployment, Traefik |
| [DevOps > Docker Production](devops/docker-production.md) | Production multi-stage Docker build |
| [DevOps > Security](devops/security.md) | Security considerations |
