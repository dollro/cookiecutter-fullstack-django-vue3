# {{cookiecutter.project_slug}}


## Django custom management commands
Note: commands like

    python manage.py createsuperuser

can in docker compose stack be executed like

    docker compose -f local.yml run --rm django python manage.py createsuperuser

### python manage.py hash_password
Creates a django-compatible hash of a string (eg a password)
Use it like

    python manage.py hash_password YOUR_STRING_HERE

### python manage.py create_or_update_superuser
 
