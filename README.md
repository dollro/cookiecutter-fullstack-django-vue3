# Cookiecutter project template for Fullstack Django Vite/Vue3 Development


This cookiecutter was initially derived by https://github.com/cookiecutter/cookiecutter-django
but enhanced by myself with the specifics needs I had in my projects.
It now implements the following

 
1. Backend (in directory backend_django)
    - Django 5 with Python 3.12
    - Postgres 17
    - REST API
    - JWT auth
    - Celery 6

2. Frontend (in directory frontend_vue)
    - Vite with Vue3
    - TailwindCSS 4
    - SASS can be used if needed (seperatly from TailWind)

3. Architecture
    - Traefik 2.9
    - Gitlab CI pipeline
        - for testing (develop branches) and multi-arch production builds (master branch)
        - full registry caching using gitlab internal registry
        - push to external registry for final production builds
        - multi-arch builds amd64 and arm64, with
            - builds of emd64 on gitlab runners
            - builds of arm64 via gitlab runner on AWS E2C instances, with automatic startup/stop of
              instances
    
3. Development Environments
    - docker environments and corresponding docker compose stacks for 
        - local development (local.yml, and dockerfiles in compose/local with envs in .envs/local)
        - production builds (production.yml, and dockerfiles in compose/production with envs in
          .envs/production)
    - local development without docker, using python venv
    - see local Makefile for a good overview of the build environments
