# syntax = docker/dockerfile:1.3
FROM python:3.12-slim-bookworm
ARG TARGETPLATFORM

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    # dependencies for building Python packages
    && apt-get install -y build-essential \
    # psycopg dependencies
    && apt-get install -y libpq-dev \
    # Translations dependencies
    && apt-get install -y gettext \
    # Uncomment below lines to enable Sphinx output to latex and pdf
    # && apt-get install -y texlive-latex-recommended \
    # && apt-get install -y texlive-fonts-recommended \
    # && apt-get install -y texlive-latex-extra \
    # && apt-get install -y latexmk \
    # install libs to get python wheels compiled also in armhf environment 
    # && apt-get install -y libxslt1-dev libffi-dev libxml2-dev libssl-dev python3-dev cargo libjpeg-dev \
    # cleaning up unused files
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Install uv for dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy pyproject.toml and uv.lock for dependency installation
COPY pyproject.toml uv.lock ./

# Install dependencies (dev, docs, and production for full autodoc coverage)
RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/uv  \
    if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
        export UV_EXTRA_INDEX_URL="https://www.piwheels.org/simple"; \
    fi && \
    uv pip install --system -r pyproject.toml --extra dev --extra docs --extra production

WORKDIR /docs

CMD make livehtml
