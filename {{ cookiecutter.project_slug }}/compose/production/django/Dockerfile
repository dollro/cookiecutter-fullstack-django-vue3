
# syntax = docker/dockerfile:1.3

################################################
# Client builder: build css, js and vue assets
################################################
FROM node:18-bookworm-slim AS pre-stage
ARG TARGETPLATFORM
RUN apt-get update \
    && apt-get install -y git python3 build-essential \
    && apt-get install -y autoconf g++ make libpng-dev libtool
#
RUN npm install -g pnpm
COPY ./frontend_vue/package.json /app/frontend_vue/package.json
#
WORKDIR /app/frontend_vue
RUN --mount=type=cache,id=pnpm-cache-$TARGETPLATFORM,target=$HOME/.local/share/pnpm/store/v3 pnpm install
#RUN pnpm install
#&& npm cache clean --force
#RUN npm --omit=optional install && npm cache clean --force
RUN npx browserslist@latest --update-db

COPY . /app

WORKDIR /app/frontend_vue
RUN chown -R node:node /app/frontend_vue
RUN pnpm run build -- --mode production
RUN rm -rf node_modules src
WORKDIR /app



###################################
# Main python build stage
###################################
FROM python:3.12-slim-bookworm AS main-stage

ENV PYTHONUNBUFFERED 1

ENV UNAME=django
ARG USER_ID=10000
ARG GROUP_ID=10001
ARG TARGETPLATFORM
RUN --mount=type=cache,id=apt-cache-$TARGETPLATFORM,target=/var/cache/apt apt-get update \
  # dependencies for building Python packages
  && apt-get install -y build-essential curl \
  # psycopg and cffi dependencies
  && apt-get install -y libpq-dev libffi-dev \
  # Pillow dependencies
  && apt-get install -y libjpeg-dev zlib1g zlib1g-dev \
  # Translations dependencies
  && apt-get install -y gettext \
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
RUN --mount=type=cache,id=pip-cache-$TARGETPLATFORM,target=/root/.cache/pip pip install -r /requirements/production.txt \
    && rm -rf /requirements

# Setup Users and Groups

# default user for production: django
#RUN addgroup --system django \
#    && adduser --system --ingroup django django

RUN export UNAME=$UNAME UID=${USER_ID} GID=${GROUP_ID} && \
    mkdir -p "/home/${UNAME}" && \
    echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd && \
    echo "${UNAME}:x:${UID}:" >> /etc/group && \
    mkdir -p /etc/sudoers.d && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} && \
    chmod 0440 /etc/sudoers.d/${UNAME} && \
    chown ${UID}:${GID} -R /home/${UNAME} && \
    gpasswd -a ${UNAME} audio


COPY --chown=$UNAME:$UNAME ./compose/production/django/entrypoint /entrypoint
RUN sed -i 's/\r$//g' /entrypoint
RUN chmod +x /entrypoint


COPY --chown=$UNAME:$UNAME ./compose/production/django/start /start
RUN sed -i 's/\r$//g' /start
RUN chmod +x /start

COPY --chown=$UNAME:$UNAME ./compose/production/django/celery/worker/start /start-celeryworker
RUN sed -i 's/\r$//g' /start-celeryworker
RUN chmod +x /start-celeryworker

COPY --chown=$UNAME:$UNAME ./compose/production/django/celery/beat/start /start-celerybeat
RUN sed -i 's/\r$//g' /start-celerybeat
RUN chmod +x /start-celerybeat

COPY --chown=$UNAME:$UNAME ./compose/production/django/celery/flower/start /start-flower
RUN sed -i 's/\r$//g' /start-flower
RUN chmod +x /start-flower

# Copy local app files to image
#COPY --chown=$UNAME:$UNAME . /app

# Copy local app file with prebuild asset files from client-builder to image
COPY --from=pre-stage --chown=$UNAME:$UNAME /app /app

#COPY --from=vue-builder --chown=$UNAME:$UNAME /frontend_vue/webpack-stats.json /app/frontend_vue/webpack-stats.json
#COPY --from=vue-builder --chown=$UNAME:$UNAME /backend_django/static/vue /app/backend_django/static/vue


WORKDIR /app
#USER django
USER ${UNAME}
ENV HOME /home/${UNAME}


ENTRYPOINT ["/entrypoint"]
