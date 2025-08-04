# syntax = docker/dockerfile:1.3
FROM python:3.12-slim-bookworm
ARG TARGETPLATFORM
ARG BUILDKIT_INLINE_CACHE

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ARG USER_ID=1000
ARG GROUP_ID=1000
ENV UNAME=django
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
  #
  # cleaning up unused files
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && rm -rf /var/lib/apt/lists/*

# copy pip configuration containing extra repos for raspberry pi wheels --> much faster build on linux/arm/v7 architecture
# Only needed if we build for linux/arm/v7 architecture, ie. delete it otherwise
COPY ./compose/production/django/pip.conf /etc/pip.conf
RUN if [ "${TARGETPLATFORM}" != "linux/arm/v7" ] ; then rm /etc/pip.conf; fi

# Requirements are installed here to ensure they will be cached.
COPY ./requirements /requirements
RUN python -m pip install --upgrade pip

# RUN sh -c 'curl https://sh.rustup.rs -sSf > ./install-rustup.sh'
# RUN chmod +x ./install-rustup.sh
# RUN ./install-rustup.sh -y

# RUN export CRYPTOGRAPHY_DONT_BUILD_RUST=1 \
#   && pip install -r /requirements/local.txt

RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/pip pip install -r /requirements/local.txt

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

COPY --chown=${USER_ID}:${GROUP_ID} ./compose/local/django/entrypoint /entrypoint
RUN sed -i 's/\r$//g' /entrypoint
RUN chmod +x /entrypoint

COPY --chown=${USER_ID}:${GROUP_ID} ./compose/local/django/start /start
RUN sed -i 's/\r$//g' /start
RUN chmod +x /start

COPY --chown=${USER_ID}:${GROUP_ID} ./compose/local/django/celery/worker/start /start-celeryworker
RUN sed -i 's/\r$//g' /start-celeryworker
RUN chmod +x /start-celeryworker

COPY --chown=${USER_ID}:${GROUP_ID} ./compose/local/django/celery/beat/start /start-celerybeat
RUN sed -i 's/\r$//g' /start-celerybeat
RUN chmod +x /start-celerybeat

COPY --chown=${USER_ID}:${GROUP_ID} ./compose/local/django/celery/flower/start /start-flower
RUN sed -i 's/\r$//g' /start-flower
RUN chmod +x /start-flower

USER ${UNAME}
ENV HOME=/home/${UNAME}

WORKDIR /app

ENTRYPOINT ["/entrypoint"]
