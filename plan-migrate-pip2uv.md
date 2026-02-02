│ Migration Plan: requirements.txt → pyproject.toml                                                                                                                 │
│                                                                                                                                                                   │
│ Goal: Unify Python dependency management using pyproject.toml as single source of truth.                                                                          │
│                                                                                                                                                                   │
│ Current State (Problems)                                                                                                                                          │
│ ┌────────────────────┬─────────────────────────────┬───────────────────┐                                                                                          │
│ │       Source       │      Example Versions       │      Status       │                                                                                          │
│ ├────────────────────┼─────────────────────────────┼───────────────────┤                                                                                          │
│ │ pyproject.toml     │ pytest>=8.0.0, mypy>=1.14.0 │ Modern ranges     │                                                                                          │
│ ├────────────────────┼─────────────────────────────┼───────────────────┤                                                                                          │
│ │ requirements/*.txt │ pytest==7.1.2, mypy==0.971  │ Outdated pins     │                                                                                          │
│ ├────────────────────┼─────────────────────────────┼───────────────────┤                                                                                          │
│ │ uv.lock            │ Full dependency tree        │ Exists but unused │                                                                                          │
│ └────────────────────┴─────────────────────────────┴───────────────────┘                                                                                          │
│ Missing test deps in requirements (caused test failures):                                                                                                         │
│ - pytest-asyncio, aiosqlite, anyio, fakeredis, pytest-timeout                                                                                                     │
│                                                                                                                                                                   │
│ Target State                                                                                                                                                      │
│                                                                                                                                                                   │
│ pyproject.toml (single source)                                                                                                                                    │
│ ├── dependencies = [...]           # base packages (always)                                                                                                       │
│ ├── [project.optional-dependencies]                                                                                                                               │
│ │   ├── dev = [...]                # development tools                                                                                                            │
│ │   ├── test = [...]               # test-specific                                                                                                                │
│ │   ├── production = [...]         # gunicorn, anymail                                                                                                            │
│ │   └── docs = [...]               # sphinx                                                                                                                       │
│ └── uv.lock                        # reproducible builds                                                                                                          │
│                                                                                                                                                                   │
│ ---                                                                                                                                                               │
│ Files to Modify                                                                                                                                                   │
│                                                                                                                                                                   │
│ 1. pyproject.toml                                                                                                                                                 │
│                                                                                                                                                                   │
│ Path: /home/rodo/Coding/sidesupport/sswebapp/pyproject.toml                                                                                                       │
│                                                                                                                                                                   │
│ Add/update optional-dependencies:                                                                                                                                 │
│ [project.optional-dependencies]                                                                                                                                   │
│ dev = [                                                                                                                                                           │
│     # Debugging                                                                                                                                                   │
│     "Werkzeug>=2.2.0",                                                                                                                                            │
│     "ipdb>=0.13.3",                                                                                                                                               │
│     "ipython>=8.0.0",                                                                                                                                             │
│     "pyOpenSSL>=25.1.0",                                                                                                                                          │
│     # Testing                                                                                                                                                     │
│     "pytest>=8.0.0",                                                                                                                                              │
│     "pytest-django>=4.9.0",                                                                                                                                       │
│     "pytest-asyncio>=0.25.0",                                                                                                                                     │
│     "pytest-cov>=6.0.0",                                                                                                                                          │
│     "pytest-timeout>=2.3.0",                                                                                                                                      │
│     "pytest-sugar>=0.9.5",                                                                                                                                        │
│     "factory-boy>=3.3.0",                                                                                                                                         │
│     "fakeredis[lua]>=2.21.0",                                                                                                                                     │
│     "aiosqlite>=0.20.0",                                                                                                                                          │
│     "anyio>=4.0.0",                                                                                                                                               │
│     # Type checking                                                                                                                                               │
│     "mypy>=1.14.0",                                                                                                                                               │
│     "django-stubs>=1.12.0",                                                                                                                                       │
│     # Code quality                                                                                                                                                │
│     "black>=24.0.0",                                                                                                                                              │
│     "ruff>=0.8.0",                                                                                                                                                │
│     "flake8>=5.0.4",                                                                                                                                              │
│     "flake8-isort>=4.2.0",                                                                                                                                        │
│     "coverage>=6.4.2",                                                                                                                                            │
│     "pylint-django>=2.5.3",                                                                                                                                       │
│     "pylint-celery>=0.3",                                                                                                                                         │
│     # Django dev                                                                                                                                                  │
│     "django-debug-toolbar>=4.2",                                                                                                                                  │
│     "django-extensions>=3.2.3",                                                                                                                                   │
│     "django-coverage-plugin>=2.0.3",                                                                                                                              │
│ ]                                                                                                                                                                 │
│                                                                                                                                                                   │
│ test = [                                                                                                                                                          │
│     "pytest>=8.0.0",                                                                                                                                              │
│     "pytest-django>=4.9.0",                                                                                                                                       │
│     "pytest-asyncio>=0.25.0",                                                                                                                                     │
│     "pytest-cov>=6.0.0",                                                                                                                                          │
│     "pytest-timeout>=2.3.0",                                                                                                                                      │
│     "factory-boy>=3.3.0",                                                                                                                                         │
│     "httpx>=0.28.0",                                                                                                                                              │
│     "fakeredis[lua]>=2.21.0",                                                                                                                                     │
│     "aiosqlite>=0.20.0",                                                                                                                                          │
│     "anyio>=4.0.0",                                                                                                                                               │
│ ]                                                                                                                                                                 │
│                                                                                                                                                                   │
│ production = [                                                                                                                                                    │
│     "gunicorn>=23.0.0",                                                                                                                                           │
│     "django-anymail[mailgun]>=10.2",                                                                                                                              │
│ ]                                                                                                                                                                 │
│                                                                                                                                                                   │
│ docs = [                                                                                                                                                          │
│     "sphinx>=3.2.1",                                                                                                                                              │
│     "sphinx-autobuild>=2020.9.1",                                                                                                                                 │
│ ]                                                                                                                                                                 │
│                                                                                                                                                                   │
│ 2. docker/local/django/Dockerfile                                                                                                                                 │
│                                                                                                                                                                   │
│ Path: /home/rodo/Coding/sidesupport/sswebapp/docker/local/django/Dockerfile                                                                                       │
│                                                                                                                                                                   │
│ Before (lines 32-43):                                                                                                                                             │
│ COPY ./backend_django/requirements /requirements                                                                                                                  │
│ RUN ... uv pip install --system -r /requirements/local.txt                                                                                                        │
│                                                                                                                                                                   │
│ After:                                                                                                                                                            │
│ COPY pyproject.toml uv.lock ./                                                                                                                                    │
│ RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/uv  \                                                                                     │
│     if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \                                                                                                             │
│         export UV_EXTRA_INDEX_URL="https://www.piwheels.org/simple"; \                                                                                            │
│     fi && \                                                                                                                                                       │
│     uv pip install --system ".[dev,test]"                                                                                                                         │
│                                                                                                                                                                   │
│ 3. docker/local/fastapi/Dockerfile                                                                                                                                │
│                                                                                                                                                                   │
│ Path: /home/rodo/Coding/sidesupport/sswebapp/docker/local/fastapi/Dockerfile                                                                                      │
│                                                                                                                                                                   │
│ Before (lines 24-32):                                                                                                                                             │
│ COPY ./backend_django/requirements /requirements                                                                                                                  │
│ RUN ... uv pip install --system -r /requirements/local.txt                                                                                                        │
│                                                                                                                                                                   │
│ After:                                                                                                                                                            │
│ COPY pyproject.toml uv.lock ./                                                                                                                                    │
│ RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/uv  \                                                                                     │
│     if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \                                                                                                             │
│         export UV_EXTRA_INDEX_URL="https://www.piwheels.org/simple"; \                                                                                            │
│     fi && \                                                                                                                                                       │
│     uv pip install --system ".[dev,test]"                                                                                                                         │
│                                                                                                                                                                   │
│ 4. docker/production/django/Dockerfile                                                                                                                            │
│                                                                                                                                                                   │
│ Path: /home/rodo/Coding/sidesupport/sswebapp/docker/production/django/Dockerfile                                                                                  │
│                                                                                                                                                                   │
│ Before (lines 71-83):                                                                                                                                             │
│ COPY ./backend_django/requirements /requirements                                                                                                                  │
│ RUN ... uv pip install --system -r /requirements/production.txt \                                                                                                 │
│     && rm -rf /requirements                                                                                                                                       │
│                                                                                                                                                                   │
│ After:                                                                                                                                                            │
│ COPY pyproject.toml uv.lock ./                                                                                                                                    │
│ RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/uv  \                                                                                     │
│     if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \                                                                                                             │
│         export UV_EXTRA_INDEX_URL="https://www.piwheels.org/simple"; \                                                                                            │
│     fi && \                                                                                                                                                       │
│     uv pip install --system ".[production]"                                                                                                                       │
│                                                                                                                                                                   │
│ 5. docker/local/docs/Dockerfile                                                                                                                                   │
│                                                                                                                                                                   │
│ Path: /home/rodo/Coding/sidesupport/sswebapp/docker/local/docs/Dockerfile                                                                                         │
│                                                                                                                                                                   │
│ Before (lines 24-30):                                                                                                                                             │
│ COPY ./requirements /requirements                                                                                                                                 │
│ RUN pip install -r /requirements/local.txt -r /requirements/production.txt                                                                                        │
│                                                                                                                                                                   │
│ After (migrate to uv for consistency):                                                                                                                            │
│ COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv                                                                                                               │
│ COPY pyproject.toml uv.lock ./                                                                                                                                    │
│ RUN uv pip install --system ".[dev,docs,production]"                                                                                                              │
│                                                                                                                                                                   │
│ 6. Makefile                                                                                                                                                       │
│                                                                                                                                                                   │
│ Path: /home/rodo/Coding/sidesupport/sswebapp/Makefile                                                                                                             │
│                                                                                                                                                                   │
│ Before (line 39):                                                                                                                                                 │
│ ~/.local/bin/uv pip install --python ${LOCAL_VENV_DIR}/bin/python -r backend_django/requirements/local.txt                                                        │
│                                                                                                                                                                   │
│ After:                                                                                                                                                            │
│ ~/.local/bin/uv pip install --python ${LOCAL_VENV_DIR}/bin/python -e ".[dev,test]"                                                                                │
│                                                                                                                                                                   │
│ ---                                                                                                                                                               │
│ Implementation Steps                                                                                                                                              │
│                                                                                                                                                                   │
│ Step 1: Update pyproject.toml                                                                                                                                     │
│                                                                                                                                                                   │
│ - Consolidate all dependencies from requirements files                                                                                                            │
│ - Organize into dev, test, production, docs extras                                                                                                                │
│ - Run uv lock to regenerate uv.lock                                                                                                                               │
│                                                                                                                                                                   │
│ Step 2: Update Dockerfiles (one at a time, test each)                                                                                                             │
│                                                                                                                                                                   │
│ 1. docker/local/django/Dockerfile                                                                                                                                 │
│ 2. docker/local/fastapi/Dockerfile                                                                                                                                │
│ 3. docker/production/django/Dockerfile                                                                                                                            │
│ 4. docker/local/docs/Dockerfile                                                                                                                                   │
│                                                                                                                                                                   │
│ Step 3: Update Makefile                                                                                                                                           │
│                                                                                                                                                                   │
│ - Change local venv installation command                                                                                                                          │
│                                                                                                                                                                   │
│ Step 4: Test locally                                                                                                                                              │
│                                                                                                                                                                   │
│ make local_docker_build                                                                                                                                           │
│ make local_docker_up                                                                                                                                              │
│ docker compose -f local.yml run --rm fastapi bash -c "pytest fastapi_server/tests/ -v"                                                                            │
│                                                                                                                                                                   │
│ Step 5: Add deprecation notice to requirements files                                                                                                              │
│                                                                                                                                                                   │
│ Add to top of each file in backend_django/requirements/:                                                                                                          │
│ # DEPRECATED: This file is deprecated and will be removed in a future release.                                                                                    │
│ # Dependencies are now managed in pyproject.toml                                                                                                                  │
│ # Install with: uv pip install ".[dev,test]" (local) or ".[production]" (prod)                                                                                    │
│                                                                                                                                                                   │
│ Files to update:                                                                                                                                                  │
│ - backend_django/requirements/base.txt                                                                                                                            │
│ - backend_django/requirements/local.txt                                                                                                                           │
│ - backend_django/requirements/production.txt                                                                                                                      │
│                                                                                                                                                                   │
│ Remove in 1-2 releases after team confirms no external dependencies on these files.                                                                               │
│                                                                                                                                                                   │
│ ---                                                                                                                                                               │
│ CI/CD Impact                                                                                                                                                      │
│                                                                                                                                                                   │
│ No direct changes needed - CI uses Dockerfiles which will be updated.                                                                                             │
│                                                                                                                                                                   │
│ Pipeline stages affected:                                                                                                                                         │
│ - test stage: Uses docker-bake-test.hcl → docker/local/django/Dockerfile                                                                                          │
│ - build stage: Uses docker-bake-production.hcl → docker/production/django/Dockerfile                                                                              │
│                                                                                                                                                                   │
│ ---                                                                                                                                                               │
│ Verification Checklist                                                                                                                                            │
│                                                                                                                                                                   │
│ - uv lock succeeds                                                                                                                                                │
│ - make local_docker_build succeeds                                                                                                                                │
│ - make local_docker_up starts all services                                                                                                                        │
│ - Django admin accessible at http://localhost:8000/admin                                                                                                          │
│ - FastAPI docs accessible at http://localhost:8001/docs                                                                                                           │
│ - FastAPI tests pass: docker compose -f local.yml run --rm fastapi pytest fastapi_server/tests/ -v                                                                │
│ - Django tests pass: docker compose -f local.yml run --rm django pytest                                                                                           │
│ - CI pipeline passes on feature branch                                                                                                                            │
│                                                                                                                                                                   │
│ ---                                                                                                                                                               │
│ Rollback Plan                                                                                                                                                     │
│                                                                                                                                                                   │
│ If issues arise:                                                                                                                                                  │
│ 1. Revert Dockerfile changes (git checkout)                                                                                                                       │
│ 2. Keep pyproject.toml updated for future migration                                                                                                               │
│ 3. Requirements files remain functional as fallback       
