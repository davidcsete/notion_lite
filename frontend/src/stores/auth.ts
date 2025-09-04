import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import apiService, { type User, type LoginRequest, type RegisterRequest } from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const _hasInitialized = ref(false)

  // Getters
  const isAuthenticated = computed(() => !!user.value)
  const userName = computed(() => user.value?.name || '')
  const userEmail = computed(() => user.value?.email || '')

  // Actions
  async function login(credentials: LoginRequest) {
    loading.value = true
    error.value = null
    
    try {
      const response = await apiService.login(credentials)
      user.value = response.data.user || null
      
      return { success: true, message: response.data.message }
    } catch (err: any) {
      const errorMessage = err.response?.data?.error || 'Login failed'
      error.value = errorMessage
      
      return { success: false, error: errorMessage }
    } finally {
      loading.value = false
    }
  }

  async function register(userData: RegisterRequest) {
    loading.value = true
    error.value = null
    
    try {
      const response = await apiService.register(userData)
      user.value = response.data.user || null
      
      return { success: true, message: response.data.message }
    } catch (err: any) {
      const errorMessage = err.response?.data?.errors?.join(', ') || 
                          err.response?.data?.error || 
                          'Registration failed'
      error.value = errorMessage
      
      return { success: false, error: errorMessage }
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    loading.value = true
    error.value = null
    
    try {
      await apiService.logout()
      user.value = null
      
      return { success: true, message: 'Successfully logged out' }
    } catch (err: any) {
      const errorMessage = err.response?.data?.error || 'Logout failed'
      error.value = errorMessage
      
      return { success: false, error: errorMessage }
    } finally {
      loading.value = false
    }
  }

  async function fetchCurrentUser() {
    // Prevent multiple simultaneous calls
    if (loading.value || _hasInitialized.value) {
      return { success: !!user.value }
    }
    
    loading.value = true
    error.value = null
    
    try {
      const response = await apiService.getCurrentUser()
      user.value = response.data.user || null
      _hasInitialized.value = true
      return { success: true }
    } catch (err: any) {
      user.value = null
      _hasInitialized.value = true
      // Don't set error for 401 - just means not authenticated
      if (err.response?.status !== 401) {
        error.value = err.response?.data?.error || 'Failed to fetch user'
      }
      return { success: false }
    } finally {
      loading.value = false
    }
  }

  async function updateProfile(userData: Partial<User>) {
    if (!user.value) return { success: false, error: 'Not authenticated' }
    
    loading.value = true
    error.value = null
    
    try {
      const response = await apiService.updateProfile(user.value.id, userData)
      user.value = response.data.user || user.value
      return { success: true, message: response.data.message }
    } catch (err: any) {
      const errorMessage = err.response?.data?.errors?.join(', ') || 
                          err.response?.data?.error || 
                          'Profile update failed'
      error.value = errorMessage
      return { success: false, error: errorMessage }
    } finally {
      loading.value = false
    }
  }

  function clearError() {
    error.value = null
  }

  function clearUser() {
    user.value = null
  }

  return {
    // State
    user,
    loading,
    error,
    _hasInitialized,
    
    // Getters
    isAuthenticated,
    userName,
    userEmail,
    
    // Actions
    login,
    register,
    logout,
    fetchCurrentUser,
    updateProfile,
    clearError,
    clearUser
  }
})