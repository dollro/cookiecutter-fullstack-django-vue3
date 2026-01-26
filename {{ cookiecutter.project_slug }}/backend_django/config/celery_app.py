import os
import sys
from pathlib import Path

from celery import Celery

# Ensure backend_django is importable
ROOT_DIR = Path(__file__).resolve(strict=True).parent.parent
sys.path.insert(0, str(ROOT_DIR.parent))

# set the default Django settings module for the 'celery' program.
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend_django.config.settings.local")

app = Celery("{{cookiecutter.project_slug}}")

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object("django.conf:settings", namespace="CELERY")

# Load task modules from all registered Django app configs.
app.autodiscover_tasks()

app.conf.beat_schedule = {

}
