from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _

class ConfigApp(AppConfig):
    name = "backend_django.site_config"
    verbose_name = _("Configuration App")

    def ready(self):
        pass