<template>
  <div class="hero min-h-screen bg-base-200">
    <div class="hero-content flex-col lg:flex-row-reverse">
      <div class="text-center lg:text-left">
        <h1 class="text-5xl font-bold">Welcome back!</h1>
        <p class="py-6">
          Sign in to your collaboration account to access your notes and work with your team in real-time.
        </p>
      </div>
      
      <div class="card shrink-0 w-full max-w-sm shadow-2xl bg-base-100">
        <form class="card-body" @submit.prevent="handleLogin">
          <div class="text-center mb-4">
            <h2 class="text-2xl font-bold">Sign In</h2>
            <p class="text-sm opacity-60 mt-2">
              Or
              <router-link 
                to="/register" 
                class="link link-primary"
              >
                create a new account
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
              placeholder="Enter your password"
              class="input input-bordered"
              required
            />
          </div>
          
          <div class="form-control mt-6">
            <button 
              type="submit"
              class="btn btn-primary"
              :class="{ 'loading': authStore.loading }"
              :disabled="authStore.loading"
            >
              {{ authStore.loading ? 'Signing in...' : 'Sign in' }}
            </button>
          </div>
          
          <!-- Demo accounts info -->
          <div class="divider">Demo Accounts</div>
          <div class="text-center text-sm opacity-70">
            <div class="space-y-1">
              <div class="badge badge-outline badge-sm">alice@example.com / password123</div>
              <div class="badge badge-outline badge-sm">bob@example.com / password123</div>
              <div class="badge badge-outline badge-sm">carol@example.com / password123</div>
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
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import Toast from '@/components/Toast.vue'

const router = useRouter()
const authStore = useAuthStore()
const toastStore = useToastStore()

const form = ref({
  email: '',
  password: ''
})

onMounted(() => {
  // Clear any previous errors
  authStore.clearError()
})

async function handleLogin() {
  const result = await authStore.login(form.value)
  
  if (result.success) {
    toastStore.showToast(result.message || 'Successfully logged in!', 'success')
    // Redirect to dashboard on successful login
    router.push('/dashboard')
  } else {
    toastStore.showToast(result.error || 'Login failed', 'error')
  }
}
</script>