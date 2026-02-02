#!/bin/bash
set -o errexit

GUARD=false
EXCLUDE_DEV=false
for arg in "$@"; do
  case $arg in
    --guard) GUARD=true ;;
    --exclude-dev) EXCLUDE_DEV=true ;;
  esac
done

if [ "$GUARD" = true ]; then
  SETUP_STATUS=$(python backend_django/manage.py shell -c \
    "from backend_django.site_config.models import SetupFlag; \
     print('true') if SetupFlag.objects.filter(setup_complete=True).exists() else print('false')")
  if [ "$SETUP_STATUS" = "true" ]; then
    echo "Setup flag found. Skipping fixture load."
    exit 0
  fi
fi

if [ "$EXCLUDE_DEV" = true ]; then
  find ./backend_django/fixtures -name '*.json' ! -name 'dev_*' -print0 | xargs -0 -r python backend_django/manage.py loaddata
else
  find ./backend_django/fixtures -name '*.json' -print0 | xargs -0 -r python backend_django/manage.py loaddata
fi

if [ "$GUARD" = true ]; then
  echo "Marking setup as complete."
  python backend_django/manage.py shell -c \
    "from backend_django.site_config.models import SetupFlag; SetupFlag.objects.create(setup_complete=True)"
fi
