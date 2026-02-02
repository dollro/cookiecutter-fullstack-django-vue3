# syntax = docker/dockerfile:1.3
FROM python:3.12-slim-bookworm
ARG TARGETPLATFORM
ARG BUILDKIT_INLINE_CACHE

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1
ARG USER_ID=1000
ARG GROUP_ID=1000
ENV UNAME django
#ENV UNAME ${USER}

RUN --mount=type=cache,id=apt-cache-$TARGETPLATFORM,target=/var/cache/apt apt-get update \
  # dependencies for building Python packages
  && apt-get install -y build-essential sudo curl \
  # psycopg and cffi dependencies
  && apt-get install -y libpq-dev libffi-dev \
  # Translations dependencies
  && apt-get install -y gettext \
  # Pillow dependencies
  && apt-get install -y libjpeg-dev zlib1g zlib1g-dev  \
  # App-specific dependencies
  #
  # cleaning up unused files
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/*

# now install Python modules via uv rather than pip
# 1. Copy the uv binary
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# 2. Copy requirements
COPY ./backend_django/requirements /requirements

# 3. Install dependencies
# - We use --mount=type=cache to speed up re-builds
# - We conditionally set the extra index URL (assuming it is piwheels) only for ARMv7
# - We use --system to install into the container's global Python environment
RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/uv  \
    if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
        export UV_EXTRA_INDEX_URL="https://www.piwheels.org/simple"; \
    fi && \
    uv pip install --system -r /requirements/local.txt


# Setup Users and Groups
RUN export UNAME=$UNAME UID=${USER_ID} GID=${GROUP_ID} && \
    mkdir -p "/home/${UNAME}" && \
    echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd && \
    echo "${UNAME}:x:${UID}:" >> /etc/group && \
    mkdir -p /etc/sudoers.d && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} && \
    chmod 0440 /etc/sudoers.d/${UNAME} && \
    chown ${UID}:${GID} -R /home/${UNAME} && \
    gpasswd -a ${UNAME} audio

COPY --chown=$UNAME:$UNAME ./docker/local/django/entrypoint /entrypoint
RUN sed -i 's/\r$//g' /entrypoint
RUN chmod +x /entrypoint

COPY --chown=$UNAME:$UNAME ./docker/local/django/start /start
RUN sed -i 's/\r$//g' /start
RUN chmod +x /start

COPY --chown=$UNAME:$UNAME ./docker/django/seed_fixtures.sh /seed_fixtures.sh
RUN sed -i 's/\r$//g' /seed_fixtures.sh
RUN chmod +x /seed_fixtures.sh

COPY --chown=$UNAME:$UNAME ./docker/local/django/celery/worker/start /start-celeryworker
RUN sed -i 's/\r$//g' /start-celeryworker
RUN chmod +x /start-celeryworker

COPY --chown=$UNAME:$UNAME ./docker/local/django/celery/beat/start /start-celerybeat
RUN sed -i 's/\r$//g' /start-celerybeat
RUN chmod +x /start-celerybeat

COPY --chown=$UNAME:$UNAME ./docker/local/django/celery/flower/start /start-flower
RUN sed -i 's/\r$//g' /start-flower
RUN chmod +x /start-flower

USER ${UNAME}
ENV HOME /home/${UNAME}

WORKDIR /app

ENTRYPOINT ["/entrypoint"]
