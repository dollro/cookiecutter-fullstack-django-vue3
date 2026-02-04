# Vue.js Frontend Structure

## Project Structure

```
frontend_vue/
├── src/
│   ├── main.js               # Application entry point
│   ├── Main.vue              # Root component
│   ├── i18n.js               # i18n configuration
│   ├── components/           # Vue components
│   │   ├── Hello.vue         # Example component
│   │   ├── HelloI18n.vue     # i18n example component
│   │   └── LoginRestAuth.vue # Authentication form
│   ├── rest/
│   │   └── rest.js           # Centralized API module (MANDATORY)
│   ├── stores/               # Pinia state management
│   │   ├── auth.js           # Authentication store
│   │   └── store_app.js      # Application store
│   ├── utils/
│   │   └── create_app_utils.js # App factory utilities
│   ├── assets/               # Static assets (css, scss, img)
│   └── locales/              # i18n translation files
├── vite.config.js            # Vite configuration
├── package.json              # Dependencies
├── .env.development          # Development environment
├── .env.production           # Production environment
└── eslint.config.js          # ESLint flat config
```

## Build Configuration

**Vite Configuration (`vite.config.js`):**

```javascript
export default defineConfig({
  build: {
    outDir: '../../backend_django/static/vue/',  // Output to Django static
    manifest: true,  // Generate manifest for Django
  },
  base: '/static/vue',  // Production asset path
  server: {
    host: '0.0.0.0',
    port: 3000,
    hmr: {
      host: 'localhost',
      port: 3000,
      protocol: 'ws',
    },
  },
  plugins: [
    vue(),
    VueI18nPlugin(),
    splitVendorChunkPlugin(),
    tailwindcss(),
  ],
});
```

## Critical Patterns

### 1. API Module (MANDATORY)

All API calls must go through `src/rest/rest.js`:

```javascript
// CORRECT
import api from '../rest/rest.js';
const response = await api.fetchData(params);

// WRONG - Never import axios directly
import axios from 'axios';  // DON'T DO THIS
```

See [State & Auth](state-and-auth.md) for the full API module architecture.

### 2. Styling (Tailwind CSS v4 Only)

No custom CSS files or `<style>` blocks allowed:

```vue
<!-- CORRECT -->
<div class="flex items-center p-4 bg-white rounded-lg shadow-md">
  <button class="px-4 py-2 bg-blue-600 text-white rounded">Submit</button>
</div>
```

### 3. Component Structure

Use Vue 3 Composition API with `<script setup>`:

```vue
<script setup>
import { ref, onMounted } from 'vue';
import api from '../rest/rest.js';

const loading = ref(false);
const data = ref(null);

async function fetchData() {
  loading.value = true;
  try {
    const response = await api.getSomeData();
    data.value = response.data;
  } finally {
    loading.value = false;
  }
}

onMounted(fetchData);
</script>

<template>
  <div class="p-4">...</div>
</template>
```

## Component Architecture

### Component Hierarchy

```
frontend_vue/src/
├── main.js                    # Entry point - multi-mount pattern
├── Main.vue                   # Root component (minimal)
├── i18n.js                    # Internationalization setup
├── components/
│   ├── Hello.vue              # Example component with assets
│   ├── HelloI18n.vue          # i18n demonstration component
│   └── LoginRestAuth.vue      # Full authentication form (login/register)
├── stores/
│   ├── auth.js                # Authentication state (Pinia)
│   └── store_app.js           # Application state
└── utils/
    └── create_app_utils.js    # App factory for multi-mount
```

### Multi-Mount Pattern

Unlike typical SPAs, this architecture mounts multiple Vue apps into different DOM elements:

```javascript
// main.js - Multi-mount strategy for Django integration
createAppInEl(Main, "#vue-main");
createAppInEl(Hello, "#vue-hello");
createAppInEl(LoginRestAuth, "#vue-login-rest_auth");
```

**Factory Function:**

```javascript
// create_app_utils.js
export const createAppInEl = (options, selector) => {
  const mountTarget = document.querySelector(selector);
  if (!mountTarget) return null;  // Safe skip if element missing

  const app = createApp(options);
  app.use(i18n);

  const pinia = createPinia();
  pinia.use(piniaPluginPersistedstate);
  app.use(pinia);

  app.mount(mountTarget);
  return app;
}
```

### Component Communication

**No Vue Router** - This template uses a multi-mount pattern where separate Vue apps are mounted to different DOM elements rendered by Django templates. Communication between components happens through:

1. **Pinia Stores** - Shared state across all mounted apps
2. **Event Bus** - Custom events for cross-component communication
3. **Props/Emits** - Standard Vue parent-child communication

```javascript
// Example: Using auth store across components
import { useAuthStore } from '../stores/auth.js'

const authStore = useAuthStore()

// Check authentication state
if (authStore.isAuthenticated) {
  // User is logged in
}

// React to auth changes
watch(() => authStore.token, (newToken) => {
  if (!newToken) {
    // Handle logout
  }
})
```

### Key Components

#### LoginRestAuth.vue (Authentication)

The main authentication component supporting both login and registration:

```
┌─────────────────────────────────────────────────────────────┐
│                    Authentication Form                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  Mode Toggle: [Login] / [Register]                      ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  Email/Username: [________________]                     ││
│  │  Password:       [________________]                     ││
│  │  (Register mode: Confirm Password)                      ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  [Submit Button]                                        ││
│  │  Error/Success Messages                                 ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Features:**

- Client-side form validation
- Dynamic form switching between login/register modes
- Real-time error feedback with conditional styling
- Loading states during API calls
- Tailwind CSS for responsive design

#### Hello.vue (Example Component)

A simple demonstration component showing:

- Basic Vue 3 Composition API usage
- Asset importing with `@/` alias
- SCSS scoped styling

#### HelloI18n.vue (i18n Example)

Demonstrates internationalization setup:

- Translation with `$t()` function
- Integration with vue-i18n

### Async Task Processing Pattern (for custom components)

When building components that trigger async tasks:

```
Submit Form → POST /api/create/ → Store request_id
                                      │
                                      ▼
              ┌──────────────────────────────────────┐
              │  Poll Loop (every 2 seconds)          │
              │  GET /status/{id}/ → check status     │
              │    ├─ pending → continue polling      │
              │    ├─ processing → continue polling   │
              │    ├─ completed → fetch results       │
              │    └─ failed → show error             │
              └──────────────────────────────────────┘
                                      │
                                      ▼
              GET /results/{id}/ → Display results
```
