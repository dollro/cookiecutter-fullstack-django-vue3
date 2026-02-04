# Security Considerations

## Authentication Security

| Layer | Implementation | Notes |
|-------|----------------|-------|
| **Password Storage** | Argon2 hashing | Django default (most secure) |
| **Token Type** | DRF TokenAuthentication | Simple, stateless tokens |
| **Token Storage** | localStorage | XSS vulnerable but standard |
| **Session** | Not used | Token-based instead |

## CSRF Protection

```python
# backend_django/config/settings/base.py
CSRF_COOKIE_SECURE = True       # HTTPS only
CSRF_COOKIE_HTTPONLY = False    # Accessible by JS (for axios)
CSRF_COOKIE_SAMESITE = "None"   # Cross-origin support
```

**Note:** CSRF is configured but currently relies primarily on token authentication.

## CORS Configuration

```python
# backend_django/config/settings/base.py
CORS_URLS_REGEX = r"^/api/.*$"    # Only API endpoints
CORS_ALLOW_CREDENTIALS = False    # No cookies needed (token auth)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",      # Vue dev server
    "http://localhost:8000",      # Django dev server
]
```

## Docker User Permissions

| Environment | UID:GID | User | Sudo Access |
|-------------|---------|------|-------------|
| **Local Dev** | 1000:1000 | django | Full (passwordless) |
| **Production** | 10000:10001 | django | None |

High UID in production prevents privilege escalation if container is compromised.

## File Upload Security

```python
# Files stored in private MEDIA_ROOT
MEDIA_ROOT = APPS_DIR / "media"  # Not publicly accessible

# Validate file extensions per upload type
# Implement in serializers/views
```

## Secret Management

| Secret | Storage | Access |
|--------|---------|--------|
| Django SECRET_KEY | `.envs/.production/.django` | Environment variable |
| External API Keys | `.envs/.production/.django` | Environment variable |
| Database Password | `.envs/.production/.django` | Environment variable |
| Registry Passwords | GitLab CI Variables | Masked in logs |

**Never Committed:**

- `.envs/` directory (gitignored)
- API keys
- Database credentials
- SSL certificates

## Network Security (Production)

```
┌─────────────────────────────────────────────────────────────────┐
│                     NETWORK ISOLATION                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  EXTERNAL (Internet)                                             │
│       │                                                          │
│       │ Port 80 only                                             │
│       ▼                                                          │
│  ┌─────────────┐                                                │
│  │   Traefik   │  ← TLS termination (Let's Encrypt)             │
│  │   (Proxy)   │  ← CSRF middleware                             │
│  └─────────────┘                                                │
│       │                                                          │
│       │ Internal network (<project>_network)                     │
│       ▼                                                          │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                  INTERNAL SERVICES                           ││
│  │  ┌─────────┐  ┌──────────┐  ┌───────────┐  ┌─────────────┐ ││
│  │  │ Django  │  │ Postgres │  │   Redis   │  │   Celery    │ ││
│  │  │ :5000   │  │  :5432   │  │   :6379   │  │  (workers)  │ ││
│  │  └─────────┘  └──────────┘  └───────────┘  └─────────────┘ ││
│  │       ↑           ↑              ↑               ↑          ││
│  │       └───────────┴──────────────┴───────────────┘          ││
│  │              No external port exposure                       ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Input Validation

**Backend (Django):**

- DRF serializers validate all API input
- File type validation by extension
- URL length limits
- Required field enforcement

**Frontend (Vue):**

- Form validation before submission
- File type filtering on input elements
- Optional field handling

## Rate Limiting

Consider implementing:

- django-ratelimit for API endpoints
- Celery task concurrency limits per user
