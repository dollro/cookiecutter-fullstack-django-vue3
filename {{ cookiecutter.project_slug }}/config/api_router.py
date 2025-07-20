from django.conf import settings
from django.urls import path, include

from rest_framework.routers import DefaultRouter, SimpleRouter

if settings.DEBUG:
    router = DefaultRouter()
else:
    router = SimpleRouter()

# router.register("users", UserViewSet)
# router.register("subscriptions", SubscriptionList3)

app_name = "backend_django"
urlpatterns = router.urls
