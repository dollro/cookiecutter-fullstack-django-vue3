from django.apps import AppConfig


class backend_djangoConfig(AppConfig):
    name = "backend_django"

    def ready(self):
        # run once if the registry is fully populated to initialize certain things
        pass