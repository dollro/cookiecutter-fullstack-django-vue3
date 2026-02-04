# Production Docker Multi-Stage Build

## Django Production Dockerfile Stages

```dockerfile
# STAGE 1: pre-stage (Node.js)
FROM node:18-bookworm-slim AS pre-stage
# - Install pnpm
# - Copy package.json and install dependencies
# - Copy entire project
# - Run: pnpm run build -- --mode production
# - Output: /app/backend_django/static/vue/

# STAGE 2: main-stage (Python)
FROM python:3.12-slim-bookworm AS main-stage
# - Install system dependencies
# - Install uv (Astral's package manager)
# - Install Python dependencies via uv from pyproject.toml
# - Copy from pre-stage: includes pre-built Vue assets
# - Setup non-root user
# - Copy start scripts
# - Write VERSION.txt
```

## Why Multi-Stage?

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BUILD SIZE COMPARISON                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Single Image (if we kept Node):                                    │
│  ├── Node.js runtime: ~300MB                                        │
│  ├── node_modules: ~500MB                                           │
│  ├── Python + packages: ~1.5GB                                      │
│  └── Total: ~2.3GB                                                  │
│                                                                      │
│  Multi-Stage (final image):                                         │
│  ├── Python + packages: ~1.5GB                                      │
│  ├── Built Vue assets: ~5MB                                         │
│  └── Total: ~1.5GB (35% smaller)                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Version Injection

```dockerfile
# Build arg passed from CI
ARG APP_VERSION=development

# Written to file for Django to read at startup
RUN echo "${APP_VERSION}" > /app/VERSION.txt
```

```python
# backend_django/config/settings/base.py reads version
version_file = ROOT_DIR / "VERSION.txt"
if version_file.exists():
    APP_VERSION = open(version_file).read().strip()
```
