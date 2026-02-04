# Celery Async Processing

## Architecture

```
┌──────────────┐      ┌─────────────┐      ┌──────────────────┐
│ Django View  │─────▶│    Redis    │◀─────│  Celery Worker   │
│ (task.delay) │      │  (Broker)   │      │ (task execution) │
└──────────────┘      └─────────────┘      └──────────────────┘
                             │
                             │
                      ┌──────▼──────┐
                      │ Celery Beat │
                      │ (Scheduler) │
                      └─────────────┘
```

## Configuration

```python
# backend_django/config/settings/base.py
CELERY_BROKER_URL = env("CELERY_BROKER_URL")  # redis://redis:6379/0
CELERY_RESULT_BACKEND = CELERY_BROKER_URL
CELERY_TASK_TIME_LIMIT = 60 * 60  # 1 hour max
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
```

## Task Pattern

```python
# backend_django/tasks.py
from celery import shared_task

@shared_task(bind=True)
def process_data_task(self, request_id):
    """Process data asynchronously."""
    # Long-running operations
    # External API calls
    # Heavy computations
```

## Status Flow

```
pending → processing → completed
                    ↘ failed
```

## Monitoring

- **Flower** (http://localhost:5555): Real-time task monitoring
- **Celery logs**: `docker compose -f local.yml logs celeryworker`

## Container Startup Process

### Django Container Lifecycle

The Django container follows a specific startup sequence controlled by entrypoint and start scripts.

#### Entrypoint Script (`docker/production/django/entrypoint`)

The entrypoint runs BEFORE the main command and handles:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENTRYPOINT EXECUTION                          │
├─────────────────────────────────────────────────────────────────┤
│  1. Set CELERY_BROKER_URL from REDIS_URL                        │
│  2. Construct DATABASE_URL from individual components           │
│  3. Wait for PostgreSQL to be ready (connection test loop)      │
│  4. Runtime Vue environment variable injection                   │
│  5. Execute the actual command (/start or /start-celeryworker)  │
└─────────────────────────────────────────────────────────────────┘
```

**Runtime Vue Environment Injection:**

Build-time placeholders in Vue assets are replaced with actual runtime values:

```bash
# In entrypoint - replaces placeholders in built JS files
sed -i 's|VITE_APP_STATIC_ROOT_PLACEHOLDER|'${VITE_APP_STATIC_ROOT}'|g' $file
sed -i 's|VITE_APP_API_ROOT_PLACEHOLDER|'${VITE_APP_API_ROOT}'|g' $file
```

This allows the same Docker image to work in different environments with different API URLs.

#### Start Script (`docker/production/django/start`)

The start script runs the Django application:

```
┌─────────────────────────────────────────────────────────────────┐
│                      START SCRIPT FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│  1. Apply database migrations                                    │
│  2. Check SetupFlag model for initial setup status              │
│     ├── If not setup: Load fixtures (excluding dev_* files)    │
│     └── Mark setup as complete                                   │
│  3. Create/update superuser from environment variables          │
│  4. Run collectstatic (production only)                         │
│  5. Start Gunicorn on 0.0.0.0:5000                              │
└─────────────────────────────────────────────────────────────────┘
```

**One-Time Fixture Loading:**

```python
# Uses SetupFlag model to ensure fixtures only load once
# Located in backend_django/site_config/models.py
from backend_django.site_config.models import SetupFlag
if not SetupFlag.objects.filter(setup_complete=True).exists():
    # Load fixtures from backend_django/fixtures/
    SetupFlag.objects.create(setup_complete=True)
```

#### Local vs Production Differences

| Aspect | Local (`/start`) | Production (`/start`) |
|--------|------------------|----------------------|
| **Server** | `runserver_plus` (Werkzeug) | Gunicorn |
| **Migrations** | `makemigrations` + `migrate` | `migrate` only |
| **Fixtures** | All fixtures from `backend_django/fixtures/` including `dev_*` | Excludes `dev_*` prefix |
| **Static files** | Not collected (Vite serves) | `collectstatic` run |

## Task Execution Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                      ASYNC TASK PROCESSING FLOW                        │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  API View                                                              │
│    │                                                                   │
│    ├── Create Request object (status: "pending")                       │
│    ├── process_data_task.delay(request_id)  ←── Async dispatch        │
│    └── Return immediately with request ID                              │
│                                                                        │
│  Celery Worker                                                         │
│    │                                                                   │
│    ├── Fetch request from database                                     │
│    ├── Update status to "processing"                                   │
│    │                                                                   │
│    ├── PHASE 1: Input Validation                                       │
│    │   ├── Validate input data                                         │
│    │   ├── Normalize formats                                           │
│    │   └── Prepare working directory                                   │
│    │                                                                   │
│    ├── PHASE 2: Core Processing                                        │
│    │   ├── Execute business logic                                      │
│    │   ├── Call external APIs if needed                                │
│    │   └── Generate output data                                        │
│    │                                                                   │
│    ├── PHASE 3: Save Results                                           │
│    │   ├── Store results in database                                   │
│    │   └── Save output files if any                                    │
│    │                                                                   │
│    ├── PHASE 4: Cleanup                                                │
│    │   └── Remove temporary files/directories                          │
│    │                                                                   │
│    └── Update status to "completed" or "failed"                        │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
```

## Celery Configuration Details

```python
# backend_django/config/celery_app.py
app = Celery("<project>")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()  # Auto-discovers tasks.py in all Django apps

# backend_django/config/settings/base.py
CELERY_BROKER_URL = env("CELERY_BROKER_URL")      # Redis connection
CELERY_RESULT_BACKEND = CELERY_BROKER_URL         # Store results in Redis
CELERY_ACCEPT_CONTENT = ["json"]                   # JSON serialization only
CELERY_TASK_TIME_LIMIT = 60 * 60                   # 1 hour max per task
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
```

## Worker Start Command

```bash
# docker/local/django/celery/worker/start
celery -A config.celery_app worker -l INFO
```

## Task Implementation Pattern

```python
# backend_django/tasks.py
from celery import shared_task
from .models import ProcessingRequest, ProcessingResult

@shared_task(bind=True)
def process_data_task(self, request_id):
    """Process data asynchronously."""
    request = ProcessingRequest.objects.get(id=request_id)

    try:
        request.status = "processing"
        request.celery_task_id = self.request.id
        request.save()

        # Phase 1: Validate and prepare
        validated_data = validate_input(request)

        # Phase 2: Core processing
        result_data = execute_business_logic(validated_data)

        # Phase 3: Save results
        ProcessingResult.objects.create(
            request=request,
            data=result_data
        )

        request.status = "completed"
        request.save()

    except Exception as e:
        request.status = "failed"
        request.error_message = str(e)
        request.save()
        raise

    finally:
        # Phase 4: Cleanup
        cleanup_temporary_files(request)
```

## Status Polling Pattern (Frontend)

```javascript
// Poll for task completion
async function pollStatus(requestId) {
  const pollInterval = setInterval(async () => {
    const response = await api.getStatus(requestId);

    if (response.data.status === 'completed') {
      clearInterval(pollInterval);
      await fetchResults(requestId);
    } else if (response.data.status === 'failed') {
      clearInterval(pollInterval);
      showError(response.data.error_message);
    }
    // Continue polling for 'pending' or 'processing'
  }, 2000);  // Poll every 2 seconds
}
```
