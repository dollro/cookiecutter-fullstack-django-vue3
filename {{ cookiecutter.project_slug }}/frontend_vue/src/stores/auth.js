import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../rest/rest'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const token = ref(null)
  const isLoading = ref(false)
  const error = ref(null)

  // Getters
  const isAuthenticated = computed(() => !!token.value)
  const username = computed(() => user.value?.username || '')

  // Actions
  async function login(credentials) {
    isLoading.value = true
    error.value = null
    
    try {
      const response = await api.login(credentials)
      token.value = response.data.key
      api.setAuthHeader(token.value)
      
      // Fetch user data after successful login
      await fetchUser()
      
      return response
    } catch (err) {
      error.value = err.response?.data?.detail || err.response?.data?.non_field_errors?.[0] || 'Login failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function register(userData) {
    isLoading.value = true
    error.value = null
    
    try {
      const response = await api.createUser(userData)
      return response
    } catch (err) {
      error.value = err.response?.data?.detail || 
                   err.response?.data?.non_field_errors?.[0] || 
                   Object.values(err.response?.data || {}).flat().join(', ') ||
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
    } catch (err) {
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
    } catch (err) {
      error.value = err.response?.data?.detail || 'Failed to fetch user data'
      // If token is invalid, clear auth state
      if (err.response?.status === 401) {
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
    paths: ['token', 'user']
  }
})
