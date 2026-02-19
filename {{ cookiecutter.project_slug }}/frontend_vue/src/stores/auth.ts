import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../rest/rest'

export interface User {
  id: number
  email: string
  display: string
  username?: string
  has_usable_password?: boolean
  [key: string]: unknown
}

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const sessionToken = ref<string | null>(null)
  const isLoading = ref<boolean>(false)
  const error = ref<string | null>(null)

  // Getters
  const isAuthenticated = computed(() => !!sessionToken.value)
  const username = computed(() => user.value?.display || user.value?.email || '')

  // Helper: extract session token and user from allauth response
  function handleAuthResponse(response: {
    data: {
      data?: { user?: User }
      meta?: { session_token?: string; is_authenticated?: boolean }
    }
  }) {
    const respData = response.data
    if (respData.meta?.session_token) {
      sessionToken.value = respData.meta.session_token
      api.setAuthHeader(sessionToken.value)
    }
    if (respData.data?.user) {
      user.value = respData.data.user
    }
  }

  // Actions
  async function login(credentials: { email: string; password: string }) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.login(credentials)
      handleAuthResponse(response)
      return response
    } catch (err: unknown) {
      const axiosErr = err as {
        response?: { data?: { errors?: Array<{ message?: string; code?: string }> } }
      }
      const errors = axiosErr.response?.data?.errors
      error.value = errors?.[0]?.message || 'Login failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function register(userData: { email: string; password: string }) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.signup(userData)
      handleAuthResponse(response)
      return response
    } catch (err: unknown) {
      const axiosErr = err as {
        response?: { data?: { errors?: Array<{ message?: string; code?: string; param?: string }> } }
      }
      const errors = axiosErr.response?.data?.errors
      error.value = errors?.map(e => e.message).join(', ') || 'Registration failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function logout() {
    isLoading.value = true
    error.value = null
    try {
      await api.logout()
    } catch (err: unknown) {
      // allauth returns 401 on successful logout (confirms unauthenticated)
      console.warn('Logout API call failed:', err)
    } finally {
      sessionToken.value = null
      user.value = null
      api.unsetAuthHeader()
      isLoading.value = false
    }
  }

  async function fetchUser() {
    if (!sessionToken.value) return
    isLoading.value = true
    error.value = null
    try {
      const response = await api.getSession()
      handleAuthResponse(response)
      return response
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number } }
      if (axiosErr.response?.status === 401) {
        await logout()
      }
      throw err
    } finally {
      isLoading.value = false
    }
  }

  function clearError() {
    error.value = null
  }

  function initialize() {
    if (sessionToken.value) {
      api.setAuthHeader(sessionToken.value)
      fetchUser().catch(() => {
        logout()
      })
    }
  }

  return {
    user,
    sessionToken,
    isLoading,
    error,
    isAuthenticated,
    username,
    login,
    register,
    logout,
    fetchUser,
    clearError,
    initialize
  }
}, {
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
