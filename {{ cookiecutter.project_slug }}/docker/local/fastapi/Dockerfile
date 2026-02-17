# syntax = docker/dockerfile:1.3
FROM python:3.13-slim-trixie
ARG TARGETPLATFORM
ARG BUILDKIT_INLINE_CACHE

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ARG USER_ID=1000
ARG GROUP_ID=1000
ENV UNAME fastapi

RUN --mount=type=cache,id=apt-cache-fastapi-$TARGETPLATFORM,target=/var/cache/apt apt-get update \
  # dependencies for building Python packages
  && apt-get install -y build-essential sudo curl \
  # psycopg and cffi dependencies
  && apt-get install -y libpq-dev libffi-dev \
  # cleaning up unused files
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/*

# now install Python modules via uv rather than pip
# 1. Copy the uv binary
COPY --from=ghcr.io/astral-sh/uv:0.10.3 /uv /bin/uv

# 2. Copy pyproject.toml for dependency installation
COPY pyproject.toml ./

# 3. Install dependencies
RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/uv  \
    if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
        export UV_EXTRA_INDEX_URL="https://www.piwheels.org/simple"; \
    fi && \
    uv pip install --system -r pyproject.toml --extra dev --extra test

# Setup Users and Groups
RUN export UNAME=$UNAME UID=${USER_ID} GID=${GROUP_ID} && \
    mkdir -p "/home/${UNAME}" && \
    echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd && \
    echo "${UNAME}:x:${UID}:" >> /etc/group && \
    mkdir -p /etc/sudoers.d && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} && \
    chmod 0440 /etc/sudoers.d/${UNAME} && \
    chown ${UID}:${GID} -R /home/${UNAME}

COPY --chown=$UNAME:$UNAME ./docker/local/fastapi/entrypoint /entrypoint
RUN sed -i 's/\r$//g' /entrypoint
RUN chmod +x /entrypoint

COPY --chown=$UNAME:$UNAME ./docker/local/fastapi/start /start
RUN sed -i 's/\r$//g' /start
RUN chmod +x /start

USER ${UNAME}
ENV HOME /home/${UNAME}
ENV PYTHONPATH /app

WORKDIR /app

ENTRYPOINT ["/entrypoint"]
