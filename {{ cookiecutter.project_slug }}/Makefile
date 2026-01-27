#!make
SHELL:=/bin/bash
PYTHON=python3.12

PROJECT_NAME={{cookiecutter.project_slug}}
LOCAL_VENVS_DIR=~/.virtualenvs
LOCAL_VENV_ENV=.envs/.local-venv/.django


LOCAL_VENV_DIR := ${LOCAL_VENVS_DIR}/${PROJECT_NAME}
PRODUCTION_VENV_DIR := ${PRODUCTION_VENVS_DIR}/${PROJECT_NAME}
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR := $(dir $(MKFILE_PATH))
FIXTURES := $(shell ls -A backend_django/fixtures 2>/dev/null)
DOCKERIMAGE_VERSION := $(shell git describe --tags --always)

### LOCAL VENV for development
local_venv_install:
	$(MAKE) local_venv_sw_setup
	$(MAKE) local_venv_db_setup
	$(MAKE) local_venv_db_migrate
	$(MAKE) local_venv_db_preseed

local_venv_sw_setup:
	sudo apt update
	sudo apt install -y postgresql-17 nodejs direnv ${PYTHON}-venv npm
	sudo apt install -y libpq-dev
	sudo apt install -y redis-server
	sudo apt install -y libjpeg-dev zlib1g-dev
	sudo apt install -y git-secret
	# Install uv package manager
	curl -LsSf https://astral.sh/uv/install.sh | sh

	mkdir -p ./log
	mkdir -p ${LOCAL_VENVS_DIR}
	chmod u+x ./cert/mkcert-amd64
	./cert/mkcert-amd64 -cert-file ./cert/cert.pem -key-file ./cert/key.pem localhost 127.0.0.1 $(uname -n) $(hostname -I | awk '{ print $1 }')
	~/.local/bin/uv venv ${LOCAL_VENV_DIR} --python ${PYTHON}
	~/.local/bin/uv pip install --python ${LOCAL_VENV_DIR}/bin/python -r backend_django/requirements/local.txt
	@( \
		source ${LOCAL_VENV_DIR}/bin/activate; \
		if [ -d .git ]; then pre-commit install; else echo "pre-commit not installed since no git repository"; fi;\
	)
	sudo npm install -g pnpm
	pnpm --dir ./frontend_vue install


local_venv_db_setup:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	sudo -E -u postgres psql -p${POSTGRES_PORT} -tc "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB}'" | grep -q 1 || sudo -E -u postgres psql -p${POSTGRES_PORT}  -c "CREATE DATABASE ${POSTGRES_DB};"
	sudo -E -u postgres psql -p${POSTGRES_PORT} -tc "SELECT 1 FROM pg_roles WHERE rolname = '${POSTGRES_USER}'" | grep -q 1 || sudo -E -u postgres psql -p${POSTGRES_PORT}  -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';"
	sudo -E -u postgres psql -p${POSTGRES_PORT} -tc "ALTER USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}'; \
		ALTER ROLE ${POSTGRES_USER} SET client_encoding TO 'utf-8'; \
		GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};"
	sudo -E -u postgres psql -p${POSTGRES_PORT} -tc "ALTER USER ${POSTGRES_USER} CREATEDB;"
	sudo -E -u postgres psql -p${POSTGRES_PORT} -d ${POSTGRES_DB} -tc "GRANT USAGE, CREATE ON SCHEMA public TO ${POSTGRES_USER};"

local_venv_db_migrate:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	${LOCAL_VENV_DIR}/bin/${PYTHON} backend_django/manage.py makemigrations
	${LOCAL_VENV_DIR}/bin/${PYTHON} backend_django/manage.py migrate

local_venv_db_preseed:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	@if [ -n "${FIXTURES}" ]; then \
	  echo "Importing fixtures..."; \
		${LOCAL_VENV_DIR}/bin/${PYTHON} backend_django/manage.py loaddata backend_django/fixtures/*.json; \
		fi

local_venv_db_delete:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	sudo -E -u postgres psql -p${POSTGRES_PORT}  -tc "SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_DB}'" | grep -q 1 && sudo -E -u postgres psql -p${POSTGRES_PORT} -c "DROP DATABASE ${POSTGRES_DB};"

local_venv_db_flush:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	${LOCAL_VENV_DIR}/bin/${PYTHON} backend_django/manage.py clear_cache
	${LOCAL_VENV_DIR}/bin/${PYTHON} backend_django/manage.py flush


local_venv_createsuperuser:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	${LOCAL_VENV_DIR}/bin/${PYTHON} backend_django/manage.py createsuperuser

lvu: local_venv_up

local_venv_up:
	@( \
	echo "Running development servers... Note: you have the start celery seperately by 'make local_venv_celery_start'"; \
	source ${LOCAL_VENV_DIR}/bin/activate; \
	./backend_django/runserver.sh -e ${LOCAL_VENV_ENV} -r all;\
	)

lvd: local_venv_django_run

local_venv_django_run:
	@( \
	source ${LOCAL_VENV_DIR}/bin/activate; \
	./backend_django/runserver.sh -e ${LOCAL_VENV_ENV} -r django;\
	)

lvv: local_venv_vue_run

local_venv_vue_run:
	@( \
	source ${LOCAL_VENV_DIR}/bin/activate; \
	./backend_django/runserver.sh -e ${LOCAL_VENV_ENV} -r vue;\
	)

local_venv_vue_build:
	pnpm --dir ./frontend_vue run build


local_venv_celery_stop:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	( \
	CELERY_NAME=${PROJECT_NAME} CELERY_VIRTUALENV_DIR=${LOCAL_VENV_DIR} CELERY_VENV_MODE=local CELERY_WORKDIR=${MKFILE_DIR} ./backend_django/celeryd-venv.sh backend_django/celery-venv.conf worker stop ; \
	CELERY_NAME=${PROJECT_NAME} CELERY_VIRTUALENV_DIR=${LOCAL_VENV_DIR} CELERY_VENV_MODE=local ./backend_django/celeryd-venv.sh backend_django/celery-venv.conf beat stop ; \
	)


local_venv_celery_start:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	( \
	CELERY_NAME=${PROJECT_NAME} CELERY_VIRTUALENV_DIR=${LOCAL_VENV_DIR} CELERY_WORKDIR=${MKFILE_DIR} CELERY_VENV_MODE=local ./backend_django/celeryd-venv.sh backend_django/celery-venv.conf worker start ; \
	CELERY_NAME=${PROJECT_NAME} CELERY_VIRTUALENV_DIR=${LOCAL_VENV_DIR} CELERY_VENV_MODE=local ./backend_django/celeryd-venv.sh backend_django/celery-venv.conf beat start ; \
	)

local_venv_celery_restart:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	( \
	CELERY_NAME=${PROJECT_NAME} CELERY_VIRTUALENV_DIR=${LOCAL_VENV_DIR} CELERY_WORKDIR=${MKFILE_DIR} CELERY_VENV_MODE=local ./backend_django/celeryd-venv.sh backend_django/celery-venv.conf worker restart ; \
	CELERY_NAME=${PROJECT_NAME} CELERY_VIRTUALENV_DIR=${LOCAL_VENV_DIR} CELERY_VENV_MODE=local ./backend_django/celeryd-venv.sh backend_django/celery-venv.conf beat restart ; \
	)


local_venv_celery_status:
	$(eval include ${LOCAL_VENV_ENV})
	$(eval export $(shell sed 's/=.*//' ${LOCAL_VENV_ENV}))
	( \
	CELERY_NAME=${PROJECT_NAME} CELERY_VIRTUALENV_DIR=${LOCAL_VENV_DIR} CELERY_WORKDIR=${MKFILE_DIR} CELERY_VENV_MODE=local ./backend_django/celeryd-venv.sh backend_django/celery-venv.conf status ; \
	)



#######################################################################################
### LOCAL DOCKER for development

local_docker_install:
	$(MAKE) local_docker_build
	$(MAKE) local_docker_preseed

local_docker_build:
# using BUILDKIT here to enable caches in pip and apt while building docker images (see corresponding Dockerfiles RUN commands)
	DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f local.yml build
	$(MAKE) local_docker_update

local_docker_update:
	docker compose -f local.yml run --rm django bash -c "python backend_django/manage.py makemigrations && python backend_django/manage.py migrate"


local_docker_up:
	docker compose -f local.yml up

local_docker_down:
	docker compose -f local.yml down

local_docker_preseed:
	docker compose -f local.yml run --rm django bash -c "find ./backend_django/fixtures -name '*.json' -print0 | xargs -0 -r python backend_django/manage.py loaddata"

local_docker_createsuperuser:
	docker compose -f local.yml run --rm django python backend_django/manage.py createsuperuser

local_docker_passwordhash:
	docker compose -f local.yml run --rm django python backend_django/manage.py passwordhash

local_docker_cleanupall:
	docker image prune -a
	docker container prune
	docker volume prune -a

########################################################################################################
### build DOCKER images for production locally (i.e. not via CI) - witjout any registry but local caching in .buidx-cache
########################################################################################################

production_docker_build_images:
	docker context ls 2>/dev/null | grep tls-environment >/dev/null || docker context create tls-environment
	docker buildx ls 2>/dev/null | grep ci-project-builder >/dev/null || docker buildx create --name ci-project-builder --driver docker-container --bootstrap --use tls-environment
	docker buildx use ci-project-builder
	docker buildx bake --file docker-local_bake-production.hcl --progress=plain all

production_docker_preseed:
	docker compose -f production.yml run --rm django bash -c "find ./backend_django/fixtures -name '*.json' ! -name 'dev_*' -print0 | xargs -0 -r python backend_django/manage.py loaddata"


######################################################################
### DOCKER deploy via context


deploy_docker_asparuha:
	docker context ls | grep "asparuha-remote" || docker context create asparuha-remote --docker "host=ssh://sshadmin@asparuha:1222"
	docker context use asparuha-remote
	docker compose --env-file .envs/.production/.django.asparuha -f deploy.asparuha.yml pull
	docker compose --env-file .envs/.production/.django.asparuha -f deploy.asparuha.yml up -d --remove-orphans
	docker context use default


down_docker_asparuha:
	docker context ls | grep "asparuha-remote" || docker context create asparuha-remote --docker "host=ssh://sshadmin@asparuha:1222"
	docker context use asparuha-remote
	docker compose -f deploy.asparuha.yml --env-file .envs/.production/.django.asparuha down
	docker context use default


deploy_docker_wolpertinger:
	docker context ls | grep "wolpertinger-remote" || docker context create wolpertinger-remote --docker "host=ssh://sshadmin@wolpertinger:1222"
	docker context use wolpertinger-remote
	docker compose -f deploy.wolpertinger.yml --env-file .envs/.production/.django pull
	docker compose -f deploy.wolpertinger.yml --env-file .envs/.production/.django up -d --remove-orphans
	docker context use default

down_docker_wolpertinger:
	docker context ls | grep "wolpertinger-remote" || docker context create wolpertinger-remote --docker "host=ssh://sshadmin@wolpertinger:1222"
	docker context use wolpertinger-remote
	docker compose -f deploy.wolpertinger.yml --env-file .envs/.production/.django down
	docker context use default
