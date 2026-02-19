# Pinia State Management & Auth Flow

## Centralized API Module

### API Module Architecture (`frontend_vue/src/rest/rest.ts`)

All frontend API communication is centralized in a single module with two axios instances:

- **`api`** — for application endpoints (`/api/v1/...`)
- **`authApi`** — for allauth headless endpoints (`/_allauth/...`)

```typescript
// API base URL for application endpoints (DRF)
axios.defaults.baseURL = import.meta.env.VITE_APP_API_ROOT;
const api = axios.create({});

// Auth API instance for allauth headless endpoints
const authApiBaseURL = import.meta.env.VITE_APP_AUTH_ROOT ||
    import.meta.env.VITE_APP_API_ROOT.replace('/api/v1', '');
const authApi = axios.create({ baseURL: authApiBaseURL });

export default {
    setAuthHeader(token: string): void {
        api.defaults.headers.common['X-Session-Token'] = token;
        authApi.defaults.headers.common['X-Session-Token'] = token;
    },
    unsetAuthHeader(): void {
        delete api.defaults.headers.common['X-Session-Token'];
        delete authApi.defaults.headers.common['X-Session-Token'];
    },
    // Auth + API methods...
}
```

### Authentication Pattern

```
┌──────────────┐      ┌──────────────────┐      ┌──────────────┐
│    Login     │      │  Store Session   │      │  Set Header  │
│  /_allauth/  │─────▶│  Token (Pinia)   │─────▶│  X-Session-  │
│  app/v1/     │      │                  │      │  Token       │
└──────────────┘      └──────────────────┘      └──────────────┘
                                                       │
                                                       ▼
                                                All subsequent
                                                requests include:
                                                X-Session-Token: xyz
```

### Authenticated File Downloads

For file downloads requiring authentication, the API module uses blob responses:

```typescript
async downloadFileByPath(urlPath: string, fallbackFilename = 'download'): Promise<void> {
    const normalizedPath = urlPath.startsWith('/') ? urlPath : `/${urlPath}`;
    const response = await api.get(normalizedPath, {
        responseType: 'blob'
    });
    const filename = getFilenameFromResponse(response, fallbackFilename);
    triggerBlobDownload(response.data, filename);
}
```

### API Method Categories

| Category | Methods | Description |
|----------|---------|-------------|
| **Auth** | `login`, `logout`, `signup`, `getSession` | User authentication (allauth headless) |
| **CRUD** | `create`, `read`, `update`, `delete` | Resource operations |
| **Processing** | `submitTask`, `getStatus`, `getResults` | Async task operations |
| **Downloads** | `downloadFileByPath` | Authenticated file downloads |

## Auth Store Architecture (`frontend_vue/src/stores/auth.ts`)

```typescript
export const useAuthStore = defineStore('auth', () => {
  // STATE
  const user = ref<User | null>(null)
  const sessionToken = ref<string | null>(null)
  const isLoading = ref<boolean>(false)
  const error = ref<string | null>(null)

  // COMPUTED (Getters)
  const isAuthenticated = computed(() => !!sessionToken.value)
  const username = computed(() => user.value?.display || user.value?.email || '')

  // Helper: extract session token and user from allauth response
  function handleAuthResponse(response) {
    const respData = response.data
    if (respData.meta?.session_token) {
      sessionToken.value = respData.meta.session_token
      api.setAuthHeader(sessionToken.value)
    }
    if (respData.data?.user) {
      user.value = respData.data.user
    }
  }

  // ACTIONS
  async function login(credentials: { email: string; password: string }) {
    const response = await api.login(credentials)
    handleAuthResponse(response)  // Token + user extracted in one step
  }

  async function register(userData: { email: string; password: string }) {
    const response = await api.signup(userData)
    handleAuthResponse(response)  // Auto-login after registration
  }

  async function logout() {
    await api.logout()  // DELETE /_allauth/app/v1/auth/session
    sessionToken.value = null
    user.value = null
    api.unsetAuthHeader()
  }

  async function fetchUser() {
    const response = await api.getSession()
    handleAuthResponse(response)
  }

  function initialize() {
    if (sessionToken.value) {
      api.setAuthHeader(sessionToken.value)
      fetchUser().catch(() => logout())
    }
  }

  return { user, sessionToken, isLoading, error, isAuthenticated, username,
           login, register, logout, fetchUser, initialize, clearError }
}, {
  // PERSISTENCE CONFIG
  persist: {
    key: 'auth',
    paths: ['sessionToken', 'user'],
    afterRestore: (ctx) => {
      if (ctx.store.sessionToken) {
        api.setAuthHeader(ctx.store.sessionToken)
      }
    }
  }
})
```

## Allauth Headless Response Format

**Login/Signup response:**
```json
{
    "status": 200,
    "data": {
        "user": {
            "id": 1,
            "display": "user@example.com",
            "has_usable_password": true,
            "email": "user@example.com"
        }
    },
    "meta": {
        "session_token": "abc123sessiontoken...",
        "is_authenticated": true
    }
}
```

**Error response:**
```json
{
    "status": 400,
    "errors": [
        { "message": "The email address is not valid.", "code": "invalid", "param": "email" }
    ]
}
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
│    │                    │ Set X-Session-Token header   │                │
│    │                    └─────────────────────────────┘                │
│    │                                     │                              │
│    │                                     ▼                              │
│    │                    ┌─────────────────────────────┐                │
│    │                    │ GET /_allauth/app/v1/auth/   │                │
│    │                    │     session                  │                │
│    │                    │ Validate token is still      │                │
│    │                    │ valid                        │                │
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
│                           │ POST /_allauth/app/v1/auth/  │            │
│                           │      login                   │            │
│                           │ {email, password}            │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │ Response:                     │            │
│                           │ { data: { user },             │            │
│                           │   meta: { session_token } }   │            │
│                           └──────────────────────────────┘            │
│                                               │                        │
│                                               ▼                        │
│                           ┌──────────────────────────────┐            │
│                           │ Store sessionToken in Pinia   │            │
│                           │ Set X-Session-Token header    │            │
│                           │ Persist to localStorage       │            │
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
  "sessionToken": "abc123sessiontoken...",
  "user": {
    "id": 1,
    "display": "john@example.com",
    "email": "john@example.com",
    "has_usable_password": true
  }
}
```

## Error Handling

Allauth headless returns errors as an array:

```typescript
// Error structure from allauth headless
const errors = err.response?.data?.errors
// errors = [{ message: "...", code: "...", param: "..." }]

// Extract first error message
error.value = errors?.[0]?.message || 'Operation failed'

// Or join all error messages
error.value = errors?.map(e => e.message).join(', ') || 'Operation failed'
```
