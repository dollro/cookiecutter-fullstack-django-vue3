from pathlib import Path

import pytest

from django.core.management import call_command

from backend_django.users.models import User
from backend_django.users.tests.factories import UserFactory


@pytest.fixture(autouse=True, scope="session")
def _load_fixtures(django_db_setup, django_db_blocker):
    """Load all JSON fixtures into the test database, guarded by SetupFlag."""
    with django_db_blocker.unblock():
        from backend_django.site_config.models import SetupFlag

        if not SetupFlag.objects.filter(setup_complete=True).exists():
            fixture_dir = Path(__file__).resolve().parent / "fixtures"
            fixtures = sorted(fixture_dir.glob("*.json"))
            if fixtures:
                call_command("loaddata", *[str(f) for f in fixtures])
            SetupFlag.objects.create(setup_complete=True)


@pytest.fixture(autouse=True)
def media_storage(settings, tmpdir):
    settings.MEDIA_ROOT = tmpdir.strpath


@pytest.fixture
def user() -> User:
    return UserFactory()
