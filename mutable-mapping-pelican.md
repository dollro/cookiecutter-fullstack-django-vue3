# Replace placeholder-sed mechanism with direct relative paths

## Analysis of the current mechanism

### How it works today

```
Build time (.env.production)          Runtime (production entrypoint)
─────────────────────────────         ─────────────────────────────────
VITE_APP_API_ROOT=                    for file in /app/.../assets/*.js:
  VITE_APP_API_ROOT_PLACEHOLDER         sed -i 's|VITE_APP_API_ROOT_PLACEHOLDER|/api/v1|g'
                  │                                         │
                  ▼                                         ▼
         Vite bakes literal                       JS now contains
         placeholder into JS                      actual "/api/v1"
```

The intent: build-once-deploy-anywhere. The Docker image has placeholder strings in compiled JS;
each deployment fills them via `sed` at container startup using runtime env vars.

### Why it's unnecessary for this project

The production env values (from `.envs/.production/.django`) are:
```
VITE_APP_API_ROOT=/api/v1
VITE_APP_STATIC_ROOT=/static
```

These are **relative paths** — identical in every deployment. There is no scenario where one
deployment uses `/api/v1` and another uses something different. The sed mechanism provides
flexibility that is never exercised.

### Problems it causes

1. **CI E2E test failures** — CI uses the local entrypoint (no sed). Built JS retains
   literal `VITE_APP_API_ROOT_PLACEHOLDER` as the axios base URL. All API calls 404.

2. **Fragile** — `sed` on minified/hashed JS files. If a placeholder string gets split
   across chunks or appears in a source map, replacement could fail silently.

3. **Maintenance burden** — every new `VITE_*` var needs a corresponding placeholder in
   `.env.production`, a sed line in the entrypoint, and the actual value in `.envs/.production/.django`.

4. **Security concern** — `sed -i 's|...|'${VITE_APP_API_ROOT}'|g'` uses unquoted shell
   expansion. If the value contained `|` (the sed delimiter) or shell metacharacters,
   it would break or behave unexpectedly.

### Why relative paths work everywhere

The Vue SPA is always served by Django (the HTML page comes from Django's template). The browser
resolves relative URLs in JS against the **page origin** (the document URL), not the script origin.

| Environment | Page origin | `/api/v1/login/` resolves to | Works? |
|---|---|---|---|
| Production | `https://app.example.com/` | `https://app.example.com/api/v1/login/` | Yes |
| Local dev (Vite HMR) | `http://localhost:8000/` | `http://localhost:8000/api/v1/login/` | Yes |
| CI E2E | `http://django:5000/` | `http://django:5000/api/v1/login/` | Yes |

Even with `DJANGO_VITE_DEV_MODE=True` (JS loaded from Vite at port 3000), the page itself
is loaded from Django at port 8000. Relative URLs resolve against Django's origin. No proxy needed.

### Alternative considered: `window.__APP_CONFIG__` injection

Django could inject runtime config into the HTML template:
```html
<script>window.__APP_CONFIG__ = { API_ROOT: "/api/v1" }</script>
```
This is the industry standard for runtime SPA config, but it's overkill here. The values
are relative paths that never change — just hardcode them in `.env.production`.

If true runtime flexibility is ever needed (e.g., CDN for static assets, API on different domain),
the `window.__APP_CONFIG__` approach can be added at that point.

## Plan

### Change 1: Hardcode values in `.env.production`

**File**: `sswebapp/frontend_vue/.env.production`

```
#NODE_ENV=production
VITE_APP_STATIC_ROOT=/static
VITE_APP_API_ROOT=/api/v1
```

### Change 2: Remove sed placeholder replacement from production entrypoint

**File**: `sswebapp/docker/production/django/entrypoint`

Remove lines 46-64 (the entire `ROOT_DIR` / sed block). Keep the postgres-ready logic
and `exec "$@"` unchanged.

### Change 3: Remove VITE_APP_* from production Django env

**File**: `sswebapp/.envs/.production/.django`

Remove these lines (no longer consumed by the entrypoint):
```
VITE_APP_STATIC_ROOT=/static
VITE_APP_API_ROOT=/api/v1
```

### Change 4: Revert the CI workaround

**File**: `.gitlab-ci.yml` (line 379-380)

Remove the `-e VITE_APP_API_ROOT=/api/v1 -e VITE_APP_STATIC_ROOT=/static` we just added,
since it's no longer needed (`.env.production` now has the real values, not placeholders):

```yaml
    # Build frontend assets (Django serves them in production mode)
    - env IMAGE_BASENAME=$IMAGE_BASENAME IMAGETAG=$IMAGETAG docker compose -f test-ci.yml run --rm node-vue bash -c "pnpm --dir ./frontend_vue run build -- --mode production"
```

## Files modified

| File | Change |
|------|--------|
| `sswebapp/frontend_vue/.env.production` | Replace placeholders with `/api/v1` and `/static` |
| `sswebapp/docker/production/django/entrypoint` | Remove sed replacement block (lines 46-64) |
| `sswebapp/.envs/.production/.django` | Remove `VITE_APP_STATIC_ROOT` and `VITE_APP_API_ROOT` lines |
| `.gitlab-ci.yml` | Revert the `-e` env var override (clean up our earlier workaround) |

## Verification

1. **CI E2E tests**: The production build now bakes `/api/v1` directly — no placeholder, no sed, no `-e` override needed. All 8 Playwright tests should pass.
2. **Local dev**: `.env.development` is unchanged (`http://localhost:8000/api/v1`). No impact.
3. **Production Docker build**: `docker/production/django/Dockerfile:30` runs `pnpm run build -- --mode production`, which reads `.env.production` and bakes `/api/v1` into the JS. The entrypoint no longer needs to sed-replace anything.
4. **Future flexibility**: If a deployment ever needs a custom API root, pass it as a Docker build arg or Vite env var at build time. Or add `window.__APP_CONFIG__` injection at that point.
