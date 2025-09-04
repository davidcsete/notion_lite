<template>
  <div class="hero min-h-screen bg-base-200">
    <div class="hero-content flex-col lg:flex-row">
      <div class="text-center lg:text-left">
        <h1 class="text-5xl font-bold">Join us today!</h1>
        <p class="py-6">
          Create your account to start collaborating on notes in real-time with your team. 
          Experience seamless document editing and sharing.
        </p>
      </div>
      
      <div class="card shrink-0 w-full max-w-sm shadow-2xl bg-base-100">
        <form class="card-body" @submit.prevent="handleRegister">
          <div class="text-center mb-4">
            <h2 class="text-2xl font-bold">Create Account</h2>
            <p class="text-sm opacity-60 mt-2">
              Or
              <router-link 
                to="/login" 
                class="link link-primary"
              >
                sign in to existing account
              </router-link>
            </p>
          </div>
          
          <!-- Error Alert -->
          <div v-if="authStore.error" class="alert alert-error mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>{{ authStore.error }}</span>
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Full Name</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              placeholder="Enter your full name"
              class="input input-bordered"
              required
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Email</span>
            </label>
            <input
              v-model="form.email"
              type="email"
              placeholder="Enter your email"
              class="input input-bordered"
              required
            />
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Password</span>
            </label>
            <input
              v-model="form.password"
              type="password"
              placeholder="Enter password (min 6 chars)"
              class="input input-bordered"
              :class="{ 'input-error': form.password.length > 0 && form.password.length < 6 }"
              required
            />
            <label class="label" v-if="form.password.length > 0 && form.password.length < 6">
              <span class="label-text-alt text-error">Password must be at least 6 characters</span>
            </label>
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Confirm Password</span>
            </label>
            <input
              v-model="form.password_confirmation"
              type="password"
              placeholder="Confirm your password"
              class="input input-bordered"
              :class="{ 'input-error': form.password_confirmation.length > 0 && form.password !== form.password_confirmation }"
              required
            />
            <label class="label" v-if="form.password_confirmation.length > 0 && form.password !== form.password_confirmation">
              <span class="label-text-alt text-error">Passwords do not match</span>
            </label>
          </div>
          
          <div class="form-control">
            <label class="label">
              <span class="label-text">Avatar URL</span>
              <span class="label-text-alt">Optional</span>
            </label>
            <input
              v-model="form.avatar_url"
              type="url"
              placeholder="https://example.com/avatar.jpg"
              class="input input-bordered"
            />
          </div>
          
          <div class="form-control mt-6">
            <button 
              type="submit"
              class="btn btn-primary"
              :class="{ 'loading': authStore.loading }"
              :disabled="authStore.loading || !isFormValid"
            >
              {{ authStore.loading ? 'Creating Account...' : 'Create Account' }}
            </button>
          </div>
          
          <!-- Form validation status -->
          <div class="text-center mt-2">
            <div class="flex justify-center space-x-2">
              <div class="badge badge-sm" :class="form.name.trim() ? 'badge-success' : 'badge-ghost'">Name</div>
              <div class="badge badge-sm" :class="form.email.includes('@') ? 'badge-success' : 'badge-ghost'">Email</div>
              <div class="badge badge-sm" :class="form.password.length >= 6 ? 'badge-success' : 'badge-ghost'">Password</div>
              <div class="badge badge-sm" :class="form.password === form.password_confirmation && form.password_confirmation ? 'badge-success' : 'badge-ghost'">Match</div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>

  <!-- Toast Component -->
  <Toast />
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import Toast from '@/components/Toast.vue'

const router = useRouter()
const authStore = useAuthStore()
const toastStore = useToastStore()

const form = ref({
  name: '',
  email: '',
  password: '',
  password_confirmation: '',
  avatar_url: ''
})

const isFormValid = computed(() => {
  return form.value.name.trim() !== '' &&
         form.value.email.trim() !== '' &&
         form.value.password.length >= 6 &&
         form.value.password === form.value.password_confirmation
})

onMounted(() => {
  // Clear any previous errors
  authStore.clearError()
  
  // If already authenticated, redirect to dashboard
  if (authStore.isAuthenticated) {
    router.push('/dashboard')
  }
})

async function handleRegister() {
  if (!isFormValid.value) {
    return
  }
  
  const result = await authStore.register({
    user: {
      name: form.value.name,
      email: form.value.email,
      password: form.value.password,
      password_confirmation: form.value.password_confirmation,
      avatar_url: form.value.avatar_url || undefined
    }
  })
  
  if (result.success) {
    toastStore.showToast(result.message || 'Account created successfully!', 'success')
    // Redirect to dashboard on successful registration
    router.push('/dashboard')
  } else {
    toastStore.showToast(result.error || 'Registration failed', 'error')
  }
}
</script>