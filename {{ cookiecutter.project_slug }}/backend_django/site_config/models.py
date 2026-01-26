from django.db import models

class SetupFlag(models.Model):
    """
    A simple flag to indicate if the initial setup (like loading fixtures)
    has been completed.
    """
    setup_complete = models.BooleanField(default=False)
