from logging import debug
from re import X
from backend_django.config import celery_app
from celery import shared_task, Task
from celery.utils.log import get_task_logger
from celery.signals import task_revoked

from django.conf import settings
from django.db.models import Q



logger = get_task_logger(__name__)




