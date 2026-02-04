# Production Deployment

## Production Docker Stack

```yaml
# production.yml services
django:       # Gunicorn serving Django
postgres:     # PostgreSQL database
redis:        # Cache & Celery broker
celeryworker: # Async task processor
celerybeat:   # Scheduled tasks
traefik:      # Reverse proxy (port 80)
```

## Traefik Configuration

```
Internet → Traefik (:80) → Django (:5000)
                        ↳ SSL termination
                        ↳ Routing rules
```

## Deployment Commands

```bash
# Deploy to specific host
make deploy_docker_<hostname>

# Uses SSH context for remote Docker operations
docker context use <hostname>-remote
docker compose -f deploy.yml up -d
```

## Volume Mounts (Production)

```yaml
volumes:
  production_postgres_data: {}       # Database files
  production_postgres_data_backups: {}
  production_traefik: {}             # SSL certificates
  production_media: {}               # User uploads
```
