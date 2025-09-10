<script setup lang="ts">
import { RouterView, useRoute, useRouter } from 'vue-router'
import { onMounted, ref, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useViewTransitions } from '@/composables/useViewTransitions'
import Toast from '@/components/Toast.vue'
import PageTransition from '@/components/PageTransition.vue'

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()
const { supportsViewTransitions, getTransitionDirection } = useViewTransitions()

const transitionDirection = ref<'forward' | 'back'>('forward')
const previousRoute = ref<string>('')

// Watch route changes to determine transition direction
watch(
  () => route.path,
  (to, from) => {
    if (from && to !== from) {
      transitionDirection.value = getTransitionDirection(to, from)
      previousRoute.value = from
    }
  }
)

onMounted(async () => {
  // Try to restore user session on app load
  // This will be handled by the router guard to avoid conflicts
})
</script>

<template>
  <div id="app" data-theme="light">
    <!-- Use native view transitions if supported, otherwise use Vue transitions -->
    <template v-if="supportsViewTransitions">
      <RouterView v-slot="{ Component, route: currentRoute }">
        <component :is="Component" :key="currentRoute.path" />
      </RouterView>
    </template>
    
    <!-- Fallback Vue transitions for browsers without View Transitions API -->
    <template v-else>
      <RouterView v-slot="{ Component, route: currentRoute }">
        <PageTransition :direction="transitionDirection">
          <component :is="Component" :key="currentRoute.path" />
        </PageTransition>
      </RouterView>
    </template>
    
    <Toast />
  </div>
</template>

<style>
/* Global styles */
html, body {
  height: 100%;
  margin: 0;
  padding: 0;
}

#app {
  min-height: 100vh;
}

/* Custom scrollbar for webkit browsers */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: hsl(var(--b2));
}

::-webkit-scrollbar-thumb {
  background: hsl(var(--bc) / 0.2);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: hsl(var(--bc) / 0.3);
}
</style>
