# Frontend-Backend Integration

## Development Flow

```
┌─────────────────────┐     ┌─────────────────────┐
│   Vite Dev Server   │     │   Django Server     │
│   localhost:3000    │────▶│   localhost:8000    │
│   (Vue.js + HMR)    │     │   (REST API)        │
└─────────────────────┘     └─────────────────────┘
```

- Frontend runs on Vite dev server (port 3000) with hot module replacement
- API requests proxied to Django (port 8000)
- CORS configured for cross-origin requests

## Production Flow

```
┌─────────────────────────────────────────────────┐
│                   Django                         │
│   ┌─────────────────────────────────────────┐   │
│   │  /static/vue/  (Pre-built Vue assets)   │   │
│   └─────────────────────────────────────────┘   │
│   ┌─────────────────────────────────────────┐   │
│   │  /api/v1/      (REST API endpoints)     │   │
│   └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

- Vue assets built into `backend_django/static/vue/`
- Django serves both static assets and API from same origin
- WhiteNoise middleware handles static file serving

## Django-Vite Integration

Django uses `django-vite` to integrate with Vite:

```python
# backend_django/config/settings/base.py
DJANGO_VITE = {
    "default": {
        "dev_mode": env.bool("DJANGO_VITE_DEV_MODE", default=False),
        "dev_server_host": "localhost",
        "dev_server_port": 3000,
        "static_url_prefix": "vue",
        "manifest_path": APPS_DIR / "static" / "vue" / ".vite" / "manifest.json",
    }
}
```

- `dev_mode=True`: Uses Vite dev server
- `dev_mode=False`: Uses built manifest for asset resolution
