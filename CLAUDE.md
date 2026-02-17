# CLAUDE.md — Cookiecutter Template Repository

## Project Identity

This is a **Cookiecutter template** that generates fullstack Django 5 + Vue 3 web applications. You are working on the **template itself**, not a generated project.

- Template variables are defined in `cookiecutter.json` (project_name, project_slug, domain_name, etc.)
- Generated output lives in `{{ cookiecutter.project_slug }}/`
- Files matching `_copy_without_render` bypass Jinja2: `*.html, *.sh, *.vue, *.js, */urls.py, *.jpg`

## Repository Layout

```
├── cookiecutter.json                  # Template variables and defaults
├── README.md                          # Template documentation
└── {{ cookiecutter.project_slug }}/   # Generated project template
    ├── backend_django/                # Django app (config, models, API, users)
    ├── frontend_vue/                  # Vue 3 app (Vite, Pinia, Tailwind)
    ├── docker/                        # Dockerfiles (local + production)
    ├── docs/                          # MkDocs documentation
    ├── .envs/                         # Environment files
    ├── local.yml                      # Docker Compose dev
    ├── production.yml                 # Docker Compose prod
    ├── pyproject.toml                 # Python deps (single source of truth)
    ├── Makefile                       # All build/run/deploy commands
    └── mkdocs.yml                     # Docs config
```

## Working with this Template

- Jinja2 syntax (`{{ cookiecutter.* }}`) is used throughout files in `{{ cookiecutter.project_slug }}/`
- To test changes: `cookiecutter . -o /tmp/test --no-input` then build/run the output
- Do NOT add Jinja2 template syntax to files matching `_copy_without_render` patterns — they are copied verbatim
- Template variables available: `project_name`, `project_slug`, `description`, `author_name`, `domain_name`, `email`, `docker_registry`, `version`

## Tech Stack (generated project)

- **Backend:** Django 5, DRF 3.16, FastAPI, PostgreSQL 17, Celery 5.5, Redis
- **Frontend:** Vue 3, Vite 5, Tailwind CSS 4, Pinia, TypeScript
- **Package managers:** uv (Python), pnpm (Node)
- **DevOps:** Docker Compose, GitLab CI, multi-arch builds (amd64/arm64)

## Code Style

- **Python:** Black (line-length 88), Ruff linting, mypy
- **Frontend:** Prettier, ESLint, TypeScript
- **Pre-commit hooks** configured in generated projects (`.pre-commit-config.yaml`)
- **`.editorconfig`:** 4 spaces for Python/RST/INI, 2 spaces for HTML/CSS/JSON/YML, tabs for Makefile

## Documentation

- Template README: `README.md` (root)
- Generated project docs: `{{ cookiecutter.project_slug }}/docs/` (MkDocs Material)
- Doc sections: development, backend, frontend, devops
