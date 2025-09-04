<template>
  <div class="toast toast-top toast-end z-50">
    <div 
      v-for="toast in toastStore.toasts" 
      :key="toast.id"
      class="alert fade-in"
      :class="getAlertClass(toast.type)"
    >
      <svg 
        xmlns="http://www.w3.org/2000/svg" 
        class="stroke-current shrink-0 h-6 w-6" 
        fill="none" 
        viewBox="0 0 24 24"
      >
        <path 
          v-if="toast.type === 'success'"
          stroke-linecap="round" 
          stroke-linejoin="round" 
          stroke-width="2" 
          d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" 
        />
        <path 
          v-else-if="toast.type === 'error'"
          stroke-linecap="round" 
          stroke-linejoin="round" 
          stroke-width="2" 
          d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" 
        />
        <path 
          v-else-if="toast.type === 'warning'"
          stroke-linecap="round" 
          stroke-linejoin="round" 
          stroke-width="2" 
          d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z" 
        />
        <path 
          v-else
          stroke-linecap="round" 
          stroke-linejoin="round" 
          stroke-width="2" 
          d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" 
        />
      </svg>
      <span>{{ toast.message }}</span>
      <button 
        @click="toastStore.removeToast(toast.id)"
        class="btn btn-sm btn-ghost btn-circle"
      >
        ✕
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useToastStore, type Toast } from '@/stores/toast'

const toastStore = useToastStore()

function getAlertClass(type: Toast['type']) {
  const classes = {
    success: 'alert-success',
    error: 'alert-error', 
    warning: 'alert-warning',
    info: 'alert-info'
  }
  return classes[type]
}
</script>

<script lang="ts">
export default {
  name: 'ToastComponent'
}
</script>