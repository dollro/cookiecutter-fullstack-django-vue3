# CLAUDE.md — Frontend (Vue 3)

## Development Commands

> **Docker is the primary development environment.** Run all commands via Docker unless you have a specific reason to use the local venv fallback.

### Docker (primary)

```bash
# From project root:
make local_docker_vue_install     # Install / update deps (pnpm install)
make local_docker_vue_lint        # Run ESLint (with auto-fix)
make local_docker_vue_build       # Production build

# Or directly:
docker compose -f local.yml run --rm node-vue pnpm install
docker compose -f local.yml run --rm node-vue pnpm run lint
docker compose -f local.yml run --rm node-vue pnpm run build
docker compose -f local.yml exec node-vue pnpm run type-check
```

### Local venv (fallback)

Only use these if Docker is not available:

```bash
make local_venv_vue_run           # Start Vite dev server
make local_venv_vue_build         # Production build
pnpm --dir ./frontend_vue install # Install deps locally
```

## Tech Stack

- **Framework:** Vue 3 (Composition API)
- **Build tool:** Vite 5
- **Styling:** Tailwind CSS 4
- **State:** Pinia
- **Language:** TypeScript
- **Package manager:** pnpm (never npm or yarn)

## Project Structure

```
src/
├── main.ts              # App entry point
├── components/          # Vue components
├── stores/              # Pinia state management
└── rest/rest.ts         # Axios API client
e2e/                     # Playwright E2E tests
```

## Testing

- **Unit tests:** `vitest` — `pnpm run test:unit`
- **E2E tests:** Playwright — `pnpm run test:e2e`
- **Type checking:** `vue-tsc` — `pnpm run type-check`

## Code Style

- **Linting:** ESLint (`eslint.config.js`)
- **Formatting:** Prettier
- **Indentation:** 2 spaces (HTML/CSS/JSON/YML), per `.editorconfig`

## Build Output

Vue assets are built into `backend_django/static/vue/` for django-vite integration.
