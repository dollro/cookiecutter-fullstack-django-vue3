# Pinia State Management & Auth Flow

## Centralized API Module

### API Module Architecture (`frontend_vue/src/rest/rest.js`)

All frontend API communication is centralized in a single module.

```javascript
// Base configuration
axios.defaults.baseURL = import.meta.env.VITE_APP_API_ROOT

const api = axios.create({});

export default {
    // Authentication
    setAuthHeader(token) {
        api.defaults.headers.common['Authorization'] = 'Token ' + token
    },
    unsetAuthHeader() {
        api.defaults.headers.common['Authorization'] = ''
    },

    // API Methods...
}
```

### Authentication Pattern

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│    Login     │      │  Store Token │      │  Set Header  │
│   /login/    │─────▶│  (Pinia)     │─────▶│  api.setAuth │
└──────────────┘      └──────────────┘      └──────────────┘
                                                   │
                                                   ▼
                                            All subsequent
                                            requests include:
                                            Authorization: Token xyz
```

### Authenticated File Downloads

For file downloads requiring authentication, the API module uses blob responses:

```javascript
async downloadFile(resourceId) {
    const response = await api.get(`/resource/download/${resourceId}/`, {
        responseType: 'blob'  // Important: receive as binary
    });
    const filename = getFilenameFromResponse(response, `file_${resourceId}.pdf`);
    triggerBlobDownload(response.data, filename);
}

function triggerBlobDownload(blob, filename) {
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
}
```

### API Method Categories

| Category | Methods | Description |
|----------|---------|-------------|
| **Auth** | `login`, `logout`, `createUser`, `getUserData` | User authentication |
| **CRUD** | `create`, `read`, `update`, `delete` | Resource operations |
| **Processing** | `submitTask`, `getStatus`, `getResults` | Async task operations |
| **Downloads** | `downloadFile`, `downloadArchive` | Authenticated file downloads |

## Auth Store Architecture (`frontend_vue/src/stores/auth.js`)

```javascript
export const useAuthStore = defineStore('auth', () => {
  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════
  const user = ref(null)
  const token = ref(null)
  const isLoading = ref(false)
  const error = ref(null)

  // ═══════════════════════════════════════════════════════════
  // COMPUTED (Getters)
  // ═══════════════════════════════════════════════════════════
  const isAuthenticated = computed(() => !!token.value)
  const username = computed(() => user.value?.username || user.value?.email || '')

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  async function login(credentials) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.login(credentials)
      token.value = response.data.key  // Token from dj-rest-auth
      api.setAuthHeader(token.value)   // Set axios default header
      await fetchUser()
    } catch (err) {
      error.value = extractErrorMessage(err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function logout() {
    try {
      await api.logout()  // Optional - continue even if fails
    } catch {}
    token.value = null
    user.value = null
    api.unsetAuthHeader()
  }

  async function fetchUser() {
    const response = await api.getUserData()
    user.value = response.data
  }

  function initialize() {
    // Called on app mount - restores session from localStorage
    if (token.value) {
      api.setAuthHeader(token.value)
      fetchUser().catch(() => logout())  // Invalid token → logout
    }
  }

  return { user, token, isLoading, error, isAuthenticated, username,
           login, logout, fetchUser, initialize, clearError }
}, {
  // ═══════════════════════════════════════════════════════════
  // PERSISTENCE CONFIG
  // ═══════════════════════════════════════════════════════════
  persist: {
    key: 'auth',
    paths: ['token', 'user'],  // Only persist these fields
    afterRestore: (ctx) => {
      // Restore auth header after page reload
      if (ctx.store.token) {
        api.setAuthHeader(ctx.store.token)
      }
    }
  }
})
```

## Authentication Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION STATE FLOW                           │
├───────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  PAGE LOAD                                                             │
│    │                                                                   │
│    ▼                                                                   │
│  ┌───────────────────────────────────────┐                            │
│  │ Check localStorage for persisted auth  │                            │
│  └───────────────────────────────────────┘                            │
│    │                                                                   │
│    ├─── Token found ────────────────────┐                              │
│    │                                     ▼                              │
│    │                    ┌─────────────────────────────┐                │
│    │                    │ Set axios Authorization     │                │
│    │                    │ header: "Token {token}"     │                │
│    │                    └─────────────────────────────┘                │
│    │                                     │                              │
│    │                                     ▼                              │
│    │                    ┌─────────────────────────────┐                │
│    │                    │ GET /api/v1/user/           │                │
│    │                    │ Validate token is still     │                │
│    │                    │ valid                       │                │
│    │                    └─────────────────────────────┘                │
│    │                           │              │                        │
│    │                      Valid │          Invalid                     │
│    │                           ▼              ▼                        │
│    │                   ┌──────────┐    ┌──────────┐                   │
│    │                   │ Show App │    │  Logout  │                   │
│    │                   └──────────┘    └──────────┘                   │
│    │                                          │                        │
│    └─── No token ─────────────────────────────┼─────┐                 │
│                                               │     │                  │
│                                               ▼     ▼                  │
│                              ┌──────────────────────────────┐         │
│                              │  Show Login Form              │         │
│                              └──────────────────────────────┘         │
│                                               │                        │
│                                               ▼                        │
│  LOGIN                    ┌──────────────────────────────┐            │
│                           │ POST /api/v1/login/          │            │
│                           │ {username, password}         │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │ Response: {key: "token123"}  │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │ Store token in Pinia state   │            │
│                           │ Set axios header             │            │
│                           │ Persist to localStorage      │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │  Navigate to Main View       │            │
│                           └──────────────────────────────┘            │
│                                                                        │
└───────────────────────────────────────────────────────────────────────┘
```

## LocalStorage Structure

```javascript
// Key: 'auth' (from persist config)
{
  "token": "abc123def456...",
  "user": {
    "pk": 1,
    "username": "john@example.com",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

## Error Handling

```javascript
function extractErrorMessage(err) {
  // Handle nested error structures from DRF
  const data = err.response?.data
  if (!data) return 'Network error'

  if (typeof data === 'string') return data
  if (data.detail) return data.detail
  if (data.non_field_errors) return data.non_field_errors[0]

  // Field-specific errors
  const firstKey = Object.keys(data)[0]
  return Array.isArray(data[firstKey]) ? data[firstKey][0] : data[firstKey]
}
```
