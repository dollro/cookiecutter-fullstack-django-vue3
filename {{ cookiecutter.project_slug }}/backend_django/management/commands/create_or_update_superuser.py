# my_app/management/commands/create_or_update_superuser.py

import os
from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.db import IntegrityError

class Command(BaseCommand):
    """
    Custom Django management command to create a superuser or update an existing one.

    This command reads credentials in the following order of precedence:
    1. Command-line arguments (--username, --email, --password)
    2. Environment variables (as a fallback for any missing arguments):
       - DJANGO_SUPERUSER_USERNAME
       - DJANGO_SUPERUSER_EMAIL
       - DJANGO_SUPERUSER_PASSWORD

    Argument Rules:
    - The --username and --email arguments must be used together.
    - If providing credentials primarily via environment variables (i.e., not using
      command-line args for username/email), you must provide all three:
      DJANGO_SUPERUSER_USERNAME, DJANGO_SUPERUSER_EMAIL, and DJANGO_SUPERUSER_PASSWORD.
    - You can mix sources, e.g., provide username/email via arguments and the
      password via the DJANGO_SUPERUSER_PASSWORD environment variable.

    If a user with the specified username exists, it updates their password and email,
    and ensures they have superuser privileges. If the user does not exist, it
    creates a new superuser with the provided details.
    """
    help = 'Creates/updates a superuser. Uses command-line args, falling back to DJANGO_SUPERUSER_* env vars.'

    def add_arguments(self, parser):
        """
        Adds command-line arguments for username, email, and password.
        These take precedence over environment variables.
        """
        parser.add_argument(
            '--username',
            type=str,
            help='Specifies the username. Overrides DJANGO_SUPERUSER_USERNAME env var. Must be used with --email.',
        )
        parser.add_argument(
            '--email',
            type=str,
            help='Specifies the email. Overrides DJANGO_SUPERUSER_EMAIL env var. Must be used with --username.',
        )
        parser.add_argument(
            '--password',
            type=str,
            help='Specifies the password. Overrides DJANGO_SUPERUSER_PASSWORD env var.',
        )

    def handle(self, *args, **options):
        """
        The main logic for the command.
        """
        User = get_user_model()

        # --- 1. Validate argument and environment variable rules ---
        # Rule: --username and --email must be used together.
        if (options['username'] and not options['email']) or \
           (options['email'] and not options['username']):
            raise CommandError(
                "The --username and --email arguments must be used together."
            )

        # Rule: If username and email are provided as env vars, password must also be an env var.
        # This check is only relevant if command-line args for user/email are not used.
        if not options['username']: # We are in environment variable mode for user/email
            env_username = os.environ.get('DJANGO_SUPERUSER_USERNAME')
            env_email = os.environ.get('DJANGO_SUPERUSER_EMAIL')
            env_password = os.environ.get('DJANGO_SUPERUSER_PASSWORD')
            if (env_username and env_email) and not env_password:
                raise CommandError(
                    "If DJANGO_SUPERUSER_USERNAME and DJANGO_SUPERUSER_EMAIL are set, "
                    "DJANGO_SUPERUSER_PASSWORD must also be set as an environment variable."
                )

        # --- 2. Resolve credentials. Command-line arguments take precedence. ---
        username = options['username'] or os.environ.get('DJANGO_SUPERUSER_USERNAME')
        email = options['email'] or os.environ.get('DJANGO_SUPERUSER_EMAIL')
        password = options['password'] or os.environ.get('DJANGO_SUPERUSER_PASSWORD')

        # --- 3. Validate that all credentials have been provided from some source ---
        if not all([username, email, password]):
            raise CommandError(
                "You must provide username, email, and password. This can be done via "
                "command-line arguments or DJANGO_SUPERUSER_* environment variables."
            )

        # --- 4. Check if user exists and either update or create ---
        try:
            # Attempt to get the user by username
            user = User.objects.get(username=username)

            # If the user exists, update their details and ensure superuser status.
            user.email = email
            user.set_password(password)
            user.is_staff = True
            user.is_superuser = True
            user.save()

            self.stdout.write(self.style.SUCCESS(
                f'Superuser "{username}" already exists. Password, email, and admin rights have been updated/ensured.'
            ))

        except User.DoesNotExist:
            # If the user does not exist, create a new one
            self.stdout.write(f'Superuser "{username}" not found. Creating a new one.')
            try:
                User.objects.create_superuser(username=username, email=email, password=password)
                self.stdout.write(self.style.SUCCESS(
                    f'Successfully created superuser "{username}".'
                ))
            except IntegrityError:
                raise CommandError(f"Could not create superuser '{username}'. A user with that username or email may already exist with a different case.")
        except Exception as e:
            raise CommandError(f"An unexpected error occurred: {e}")
