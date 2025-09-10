import { ref, nextTick } from 'vue'
import type { Router } from 'vue-router'

export interface ViewTransitionOptions {
  name?: string
  direction?: 'forward' | 'back'
  type?: 'slide' | 'fade' | 'scale'
}

// Check if browser supports View Transitions API
const supportsViewTransitions = () => {
  return typeof document !== 'undefined' && 'startViewTransition' in document
}

export function useViewTransitions(router?: Router) {
  const isTransitioning = ref(false)
  const transitionDirection = ref<'forward' | 'back'>('forward')

  // Apply transition class to document for CSS targeting
  const applyTransitionClass = (options: ViewTransitionOptions) => {
    if (options.name) {
      document.documentElement.classList.add(`view-transition-${options.name}`)
    }
  }

  // Remove transition class after transition
  const removeTransitionClass = (options: ViewTransitionOptions) => {
    if (options.name) {
      document.documentElement.classList.remove(`view-transition-${options.name}`)
    }
  }

  // Navigate with view transition
  const navigateWithTransition = async (
    to: string | { name: string; params?: any },
    options: ViewTransitionOptions = {}
  ) => {
    if (!router) {
      console.warn('Router not provided to useViewTransitions')
      return
    }

    isTransitioning.value = true
    transitionDirection.value = options.direction || 'forward'

    if (supportsViewTransitions()) {
      // Use native View Transitions API
      applyTransitionClass(options)
      
      const transition = (document as any).startViewTransition(async () => {
        await router.push(to)
        await nextTick()
      })

      transition.finished.finally(() => {
        removeTransitionClass(options)
        isTransitioning.value = false
      })
    } else {
      // Fallback for browsers without View Transitions API
      await router.push(to)
      isTransitioning.value = false
    }
  }

  // Transition for programmatic DOM updates
  const transitionElement = async (
    element: HTMLElement,
    updateFn: () => void | Promise<void>,
    options: ViewTransitionOptions = {}
  ) => {
    if (supportsViewTransitions()) {
      const transition = (document as any).startViewTransition(async () => {
        await updateFn()
        await nextTick()
      })

      return transition.finished
    } else {
      // Fallback animation
      element.style.transition = 'all 0.3s ease-in-out'
      element.style.opacity = '0'
      
      setTimeout(async () => {
        await updateFn()
        element.style.opacity = '1'
      }, 150)
    }
  }

  // Get transition name based on route
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

  // Determine transition direction based on route hierarchy
  const getTransitionDirection = (to: string, from: string): 'forward' | 'back' => {
    const routeHierarchy = [
      '/login',
      '/register', 
      '/dashboard',
      '/notes',
      '/notes/:id'
    ]

    const toIndex = routeHierarchy.findIndex(route => {
      if (route === '/notes/:id') return to.startsWith('/notes/') && to !== '/notes'
      return to === route
    })

    const fromIndex = routeHierarchy.findIndex(route => {
      if (route === '/notes/:id') return from.startsWith('/notes/') && from !== '/notes'
      return from === route
    })

    return toIndex > fromIndex ? 'forward' : 'back'
  }

  return {
    isTransitioning,
    transitionDirection,
    supportsViewTransitions: supportsViewTransitions(),
    navigateWithTransition,
    transitionElement,
    getTransitionName,
    getTransitionDirection
  }
}