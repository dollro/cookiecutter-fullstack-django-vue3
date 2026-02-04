import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../rest/rest'

export interface User {
  username: string
  email: string
  [key: string]: unknown
}

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const token = ref<string | null>(null)
  const isLoading = ref<boolean>(false)
  const error = ref<string | null>(null)

  // Getters
  const isAuthenticated = computed(() => !!token.value)
  const username = computed(() => user.value?.username || '')

  // Actions
  async function login(credentials: Record<string, string>) {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.login(credentials)
      token.value = response.data.key
      api.setAuthHeader(token.value)

      // Fetch user data after successful login
      await fetchUser()

      return response
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string; non_field_errors?: string[] } } }
      error.value = axiosErr.response?.data?.detail || axiosErr.response?.data?.non_field_errors?.[0] || 'Login failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function register(userData: Record<string, string>) {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.createUser(userData)
      return response
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { detail?: string; non_field_errors?: string[]; [key: string]: unknown } } }
      error.value = axiosErr.response?.data?.detail ||
                   axiosErr.response?.data?.non_field_errors?.[0] ||
                   Object.values(axiosErr.response?.data || {}).flat().join(', ') ||
                   'Registration failed'
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
      console.warn('Logout API call failed:', err)
      // Continue with local logout even if API call fails
    } finally {
      // Clear local state regardless of API response
      token.value = null
      user.value = null
      api.unsetAuthHeader()
      isLoading.value = false
    }
  }

  async function fetchUser() {
    if (!token.value) return

    isLoading.value = true
    error.value = null

    try {
      const response = await api.getUserData()
      user.value = response.data
      return response
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string } } }
      error.value = axiosErr.response?.data?.detail || 'Failed to fetch user data'
      // If token is invalid, clear auth state
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

  // Initialize auth state from token if it exists
  function initialize() {
    if (token.value) {
      api.setAuthHeader(token.value)
      fetchUser().catch(() => {
        // If fetching user fails, clear the stored token
        logout()
      })
    }
  }

  return {
    // State
    user,
    token,
    isLoading,
    error,

    // Getters
    isAuthenticated,
    username,

    // Actions
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
    paths: ['token', 'user'],
    // Set auth header immediately after state is restored from localStorage
    // This ensures the token is available before any component mounts
    afterRestore: (ctx) => {
      if (ctx.store.token) {
        api.setAuthHeader(ctx.store.token)
      }
    }
  }
})
