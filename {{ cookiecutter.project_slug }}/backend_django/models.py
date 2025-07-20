from celery.utils.functional import uniq
from django.db import models
from django.contrib.auth import get_user_model

# from django.db.models.fields import NullBooleanField
from django.contrib.sites.models import Site
import logging
from django.core.validators import MinValueValidator, MaxValueValidator

logger = logging.getLogger(__name__)


User = get_user_model()

