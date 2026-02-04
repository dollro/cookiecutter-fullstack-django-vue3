<template>
  <div class="flex items-center justify-center min-h-screen">
    <div class="bg-white rounded-lg shadow-lg p-8 max-w-md w-full">
      <h2 class="text-2xl font-bold text-center text-gray-800 mb-6">
        {{ mode === 'register' ? 'Create an Account' : 'Sign In' }}
      </h2>
      
      <!-- Success Message -->
      <div v-if="successMessage" class="mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded">
        {{ successMessage }}
      </div>
      
      <!-- Error Message -->
      <div v-if="authStore.error" class="mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded">
        {{ authStore.error }}
      </div>
      
      <!-- User Info (when logged in) -->
      <div v-if="authStore.isAuthenticated" class="mb-4 p-4 bg-blue-100 border border-blue-400 text-blue-700 rounded">
        <p class="font-semibold">Welcome, {{ authStore.username }}!</p>
        <p class="text-sm">You are successfully logged in.</p>
        <button 
          @click="handleLogout" 
          :disabled="authStore.isLoading"
          class="mt-2 px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 disabled:bg-gray-400 disabled:cursor-not-allowed"
        >
          <span v-if="authStore.isLoading">Logging out...</span>
          <span v-else>Logout</span>
        </button>
      </div>
      
      <form v-if="!authStore.isAuthenticated" @submit.prevent="handleSubmit" novalidate>
        <!-- Login Form Fields -->
        <template v-if="mode === 'login'">
          <div class="mb-4">
            <label for="login-username" class="block text-gray-700 font-semibold mb-2">Username or Email</label>
            <input 
              type="text" 
              id="login-username" 
              v-model="loginData.username"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
              :class="{ 'border-red-500': errors.username }"
              placeholder="Enter your username or email" 
              required
            >
            <p v-if="errors.username" class="text-red-500 text-sm mt-2">{{ errors.username }}</p>
          </div>
          
          <div class="mb-4">
            <label for="login-password" class="block text-gray-700 font-semibold mb-2">Password</label>
            <input 
              type="password" 
              id="login-password" 
              v-model="loginData.password"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
              :class="{ 'border-red-500': errors.password }"
              placeholder="Enter your password" 
              required
            >
            <p v-if="errors.password" class="text-red-500 text-sm mt-2">{{ errors.password }}</p>
          </div>
        </template>

        <!-- Registration Form Fields -->
        <template v-else>
          <div class="mb-4">
            <label for="username" class="block text-gray-700 font-semibold mb-2">Username</label>
            <input 
              type="text" 
              id="username" 
              v-model="formData.username"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
              :class="{ 'border-red-500': errors.username }"
              placeholder="Enter your username" 
              required
            >
            <p v-if="errors.username" class="text-red-500 text-sm mt-2">{{ errors.username }}</p>
          </div>
          
          <div class="mb-4">
            <label for="email" class="block text-gray-700 font-semibold mb-2">Email</label>
            <input 
              type="email" 
              id="email" 
              v-model="formData.email"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
              :class="{ 'border-red-500': errors.email }"
              placeholder="Enter your email" 
              required
            >
            <p v-if="errors.email" class="text-red-500 text-sm mt-2">{{ errors.email }}</p>
          </div>
          
          <div class="mb-4">
            <label for="password1" class="block text-gray-700 font-semibold mb-2">Password</label>
            <input 
              type="password" 
              id="password1" 
              v-model="formData.password1"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
              :class="{ 'border-red-500': errors.password1 }"
              placeholder="Enter your password" 
              required
            >
            <p v-if="errors.password1" class="text-red-500 text-sm mt-2">{{ errors.password1 }}</p>
          </div>
          
          <div class="mb-4">
            <label for="password2" class="block text-gray-700 font-semibold mb-2">Confirm Password</label>
            <input 
              type="password" 
              id="password2" 
              v-model="formData.password2"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
              :class="{ 'border-red-500': errors.password2 }"
              placeholder="Confirm your password" 
              required
            >
            <p v-if="errors.password2" class="text-red-500 text-sm mt-2">{{ errors.password2 }}</p>
          </div>
        </template>
        
        <button 
          type="submit" 
          :disabled="authStore.isLoading"
          class="w-full bg-blue-500 text-white py-2 rounded-lg font-semibold hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-50 disabled:bg-gray-400 disabled:cursor-not-allowed"
        >
          <span v-if="authStore.isLoading && mode === 'login'">Signing In...</span>
          <span v-else-if="authStore.isLoading && mode === 'register'">Registering...</span>
          <span v-else-if="mode === 'login'">Sign In</span>
          <span v-else>Register</span>
        </button>
      </form>
      
      <p v-if="!authStore.isAuthenticated" class="text-center text-gray-600 mt-4">
        <template v-if="mode === 'register'">
          Already have an account? 
          <a href="#" @click="switchMode" class="text-blue-500 font-semibold hover:underline">Sign In</a>
        </template>
        <template v-else>
          Don't have an account? 
          <a href="#" @click="switchMode" class="text-blue-500 font-semibold hover:underline">Register</a>
        </template>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()

// Mode state: 'login' or 'register'
const mode = ref('register')

// Registration form data
const formData = reactive({
  username: '',
  email: '',
  password1: '',
  password2: ''
})

// Login form data
const loginData = reactive({
  username: '',
  password: ''
})

// Local validation errors
const errors = ref<Record<string, string>>({})
const successMessage = ref('')

// Validation function for registration
const validateRegisterForm = () => {
  const newErrors: Record<string, string> = {}
  
  // Username validation
  if (!formData.username.trim()) {
    newErrors.username = 'Username is required'
  } else if (formData.username.length < 3) {
    newErrors.username = 'Username must be at least 3 characters long'
  }
  
  // Email validation
  if (!formData.email.trim()) {
    newErrors.email = 'Email is required'
  } else {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address'
    }
  }
  
  // Password validation
  if (!formData.password1) {
    newErrors.password1 = 'Password is required'
  } else if (formData.password1.length < 8) {
    newErrors.password1 = 'Password must be at least 8 characters long'
  }
  
  // Confirm password validation
  if (!formData.password2) {
    newErrors.password2 = 'Please confirm your password'
  } else if (formData.password1 !== formData.password2) {
    newErrors.password2 = 'Passwords do not match'
  }
  
  errors.value = newErrors
  return Object.keys(newErrors).length === 0
}

// Validation function for login
const validateLoginForm = () => {
  const newErrors: Record<string, string> = {}
  
  // Username/email validation
  if (!loginData.username.trim()) {
    newErrors.username = 'Username or email is required'
  }
  
  // Password validation
  if (!loginData.password) {
    newErrors.password = 'Password is required'
  }
  
  errors.value = newErrors
  return Object.keys(newErrors).length === 0
}

// Handle registration
const handleRegister = async () => {
  try {
    await authStore.register({
      username: formData.username,
      email: formData.email,
      password1: formData.password1,
      password2: formData.password2
    })
    
    // If registration is successful
    successMessage.value = 'Account created successfully! You can now sign in with your credentials.'
    
    // Clear form
    Object.keys(formData).forEach(key => {
      formData[key] = ''
    })
    errors.value = {}
    
  } catch (error) {
    console.error('Registration failed:', error)
    // Error is handled by the auth store and displayed in the template
  }
}

// Handle login
const handleLogin = async () => {
  try {
    // Since Django uses email-based authentication, we need to send 'email' field
    await authStore.login({
      email: loginData.username, // The field name in Django is 'email' not 'username'
      password: loginData.password
    })
    
    // If login is successful
    successMessage.value = `Welcome back, ${authStore.username}! You are now logged in.`
    
    // Clear form
    loginData.username = ''
    loginData.password = ''
    errors.value = {}
    
  } catch (error) {
    console.error('Login failed:', error)
    // Error is handled by the auth store and displayed in the template
  }
}

// Form submission handler
const handleSubmit = async () => {
  // Clear previous messages
  authStore.clearError()
  successMessage.value = ''
  
  // Validate form based on mode
  const isValid = mode.value === 'login' ? validateLoginForm() : validateRegisterForm()
  
  if (!isValid) {
    return
  }
  
  // Handle submission based on mode
  if (mode.value === 'login') {
    await handleLogin()
  } else {
    await handleRegister()
  }
}

// Handle logout
const handleLogout = async () => {
  try {
    await authStore.logout()
    successMessage.value = 'You have been successfully logged out.'
  } catch (error) {
    console.error('Logout failed:', error)
  }
}

// Switch between login and register modes
const switchMode = (event: MouseEvent) => {
  event.preventDefault()
  
  // Clear any messages and errors
  authStore.clearError()
  successMessage.value = ''
  errors.value = {}
  
  // Clear forms
  Object.keys(formData).forEach(key => {
    formData[key] = ''
  })
  loginData.username = ''
  loginData.password = ''
  
  // Switch mode
  mode.value = mode.value === 'login' ? 'register' : 'login'
}

// Initialize auth store on component mount
onMounted(() => {
  authStore.initialize()
})
</script>
