import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { nextTick } from 'vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      redirect: '/dashboard'
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue'),
      meta: { requiresGuest: true }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('../views/DashboardView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/notes',
      name: 'notes',
      component: () => import('../views/NotesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/notes/:id',
      name: 'note-editor',
      component: () => import('../views/NoteEditorView.vue'),
      meta: { requiresAuth: true }
    }
  ],
})

// Helper function to check if browser supports View Transitions
const supportsViewTransitions = () => {
  return typeof document !== 'undefined' && 'startViewTransition' in document
}

// Helper function to get transition name based on route
const getTransitionName = (to: string, from: string): string => {
  const routeTransitions: Record<string, string> = {
    '/dashboard': 'dashboard',
    '/notes': 'notes',
    '/login': 'auth',
    '/register': 'auth'
  }

  // Check for note editor routes
  if (to.startsWith('/notes/') && to !== '/notes') {
    return 'editor'
  }

  return routeTransitions[to] || 'default'
}

// Navigation guards
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Initialize auth state if not done yet
  if (!authStore._hasInitialized) {
    await authStore.fetchCurrentUser()
  }

  // Check if route requires authentication
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
    return
  }

  // Check if route requires guest (not authenticated)
  if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next('/dashboard')
    return
  }

  next()
})

// Add view transition support
router.beforeResolve(async (to, from) => {
  if (supportsViewTransitions() && from.name && to.name !== from.name) {
    const transitionName = getTransitionName(to.path, from.path)
    
    // Add transition class to document
    document.documentElement.classList.add(`view-transition-${transitionName}`)
    
    // Start view transition
    const transition = (document as any).startViewTransition(async () => {
      // The actual navigation will happen after this function
      await nextTick()
    })

    // Clean up transition class after transition
    transition.finished.finally(() => {
      document.documentElement.classList.remove(`view-transition-${transitionName}`)
    })
  }
})

export default router
