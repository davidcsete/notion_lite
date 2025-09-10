import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { useViewTransitions } from '../useViewTransitions'
import { createRouter, createWebHistory } from 'vue-router'

// Mock document.startViewTransition
const mockStartViewTransition = vi.fn()
let originalStartViewTransition: any

beforeEach(() => {
  originalStartViewTransition = (document as any).startViewTransition
  ;(document as any).startViewTransition = mockStartViewTransition
})

afterEach(() => {
  if (originalStartViewTransition) {
    ;(document as any).startViewTransition = originalStartViewTransition
  } else {
    delete (document as any).startViewTransition
  }
})

// Mock router
const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: { template: '<div>Home</div>' } },
    { path: '/notes', component: { template: '<div>Notes</div>' } },
    { path: '/notes/1', component: { template: '<div>Note Editor</div>' } }
  ]
})

describe('useViewTransitions', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockStartViewTransition.mockReturnValue({
      finished: Promise.resolve()
    })
  })

  describe('Browser Support Detection', () => {
    it('detects View Transitions API support', () => {
      const { supportsViewTransitions } = useViewTransitions()
      expect(supportsViewTransitions).toBe(true)
    })

    it('handles missing View Transitions API', () => {
      // Temporarily remove the API
      delete (document as any).startViewTransition
      
      const { supportsViewTransitions } = useViewTransitions()
      expect(supportsViewTransitions).toBe(false)
      
      // Restore the API
      ;(document as any).startViewTransition = mockStartViewTransition
    })
  })

  describe('Navigation with Transitions', () => {
    it('navigates with View Transitions API when supported', async () => {
      const { navigateWithTransition } = useViewTransitions(router)
      
      await navigateWithTransition('/notes', { name: 'notes' })
      
      expect(mockStartViewTransition).toHaveBeenCalled()
    })

    it('falls back to regular navigation when API not supported', async () => {
      // Mock API as not supported
      delete (document as any).startViewTransition
      
      const pushSpy = vi.spyOn(router, 'push')
      const { navigateWithTransition } = useViewTransitions(router)
      
      await navigateWithTransition('/notes')
      
      expect(pushSpy).toHaveBeenCalledWith('/notes')
      
      // Restore API
      ;(document as any).startViewTransition = mockStartViewTransition
    })

    it('handles navigation with route objects', async () => {
      const { navigateWithTransition } = useViewTransitions(router)
      
      await navigateWithTransition({ name: 'notes', params: { id: '1' } })
      
      expect(mockStartViewTransition).toHaveBeenCalled()
    })
  })

  describe('Transition Direction Detection', () => {
    it('detects forward navigation', () => {
      const { getTransitionDirection } = useViewTransitions()
      
      const direction = getTransitionDirection('/notes/1', '/notes')
      expect(direction).toBe('forward')
    })

    it('detects backward navigation', () => {
      const { getTransitionDirection } = useViewTransitions()
      
      const direction = getTransitionDirection('/notes', '/notes/1')
      expect(direction).toBe('back')
    })

    it('handles same-level navigation', () => {
      const { getTransitionDirection } = useViewTransitions()
      
      const direction = getTransitionDirection('/notes', '/dashboard')
      expect(direction).toBe('forward')
    })
  })

  describe('Transition Name Generation', () => {
    it('generates correct transition names for routes', () => {
      const { getTransitionName } = useViewTransitions()
      
      expect(getTransitionName('/dashboard', '/')).toBe('dashboard')
      expect(getTransitionName('/notes', '/dashboard')).toBe('notes')
      expect(getTransitionName('/notes/1', '/notes')).toBe('editor')
      expect(getTransitionName('/login', '/')).toBe('auth')
    })

    it('returns default for unknown routes', () => {
      const { getTransitionName } = useViewTransitions()
      
      expect(getTransitionName('/unknown', '/')).toBe('default')
    })
  })

  describe('Element Transitions', () => {
    it('transitions elements with View Transitions API', async () => {
      const { transitionElement } = useViewTransitions()
      const element = document.createElement('div')
      const updateFn = vi.fn()
      
      await transitionElement(element, updateFn)
      
      expect(mockStartViewTransition).toHaveBeenCalled()
      expect(updateFn).toHaveBeenCalled()
    })

    it('falls back to CSS transitions when API not supported', async () => {
      // Mock API as not supported
      delete (document as any).startViewTransition
      
      const { transitionElement } = useViewTransitions()
      const element = document.createElement('div')
      const updateFn = vi.fn()
      
      // Mock setTimeout for fallback animation
      vi.useFakeTimers()
      
      const promise = transitionElement(element, updateFn)
      
      // Fast-forward time
      vi.advanceTimersByTime(150)
      
      await promise
      
      expect(updateFn).toHaveBeenCalled()
      expect(element.style.transition).toBe('all 0.3s ease-in-out')
      
      vi.useRealTimers()
      
      // Restore API
      ;(document as any).startViewTransition = mockStartViewTransition
    })
  })

  describe('Error Handling', () => {
    it('handles navigation errors gracefully', async () => {
      const { navigateWithTransition } = useViewTransitions(router)
      
      // Mock router.push to throw an error
      vi.spyOn(router, 'push').mockRejectedValue(new Error('Navigation failed'))
      
      // Should not throw
      await expect(navigateWithTransition('/invalid')).resolves.toBeUndefined()
    })

    it('handles View Transition API errors', async () => {
      mockStartViewTransition.mockReturnValue({
        finished: Promise.reject(new Error('Transition failed'))
      })
      
      const { navigateWithTransition } = useViewTransitions(router)
      
      // Should not throw
      await expect(navigateWithTransition('/notes')).resolves.toBeUndefined()
    })
  })

  describe('State Management', () => {
    it('tracks transition state', async () => {
      const { isTransitioning, navigateWithTransition } = useViewTransitions(router)
      
      expect(isTransitioning.value).toBe(false)
      
      const navigationPromise = navigateWithTransition('/notes')
      expect(isTransitioning.value).toBe(true)
      
      await navigationPromise
      expect(isTransitioning.value).toBe(false)
    })

    it('updates transition direction', () => {
      const { transitionDirection, getTransitionDirection } = useViewTransitions()
      
      const direction = getTransitionDirection('/notes', '/dashboard')
      expect(direction).toBe('forward')
      
      // Direction should be reactive
      expect(transitionDirection.value).toBeDefined()
    })
  })
})