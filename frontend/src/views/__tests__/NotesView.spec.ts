import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import { createPinia, setActivePinia } from 'pinia'
import NotesView from '../NotesView.vue'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import apiService from '@/services/api'

// Mock API service
vi.mock('@/services/api', () => ({
  default: {
    getNotes: vi.fn(),
    createNote: vi.fn(),
    deleteNote: vi.fn(),
    getCollaborations: vi.fn(),
  }
}))

// Mock router
const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/notes', component: NotesView },
    { path: '/notes/:id', component: { template: '<div>Note Editor</div>' } },
    { path: '/dashboard', component: { template: '<div>Dashboard</div>' } },
    { path: '/login', component: { template: '<div>Login</div>' } }
  ]
})

const mockOwner = {
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  avatar_url: undefined
}

const mockNotes = [
  {
    id: 1,
    title: 'Test Note 1',
    content: { type: 'doc', content: [] },
    owner: mockOwner,
    user_role: 'owner',
    collaborators_count: 2,
    updated_at: '2024-01-01T12:00:00Z',
    created_at: '2024-01-01T10:00:00Z'
  },
  {
    id: 2,
    title: 'Test Note 2',
    content: { type: 'doc', content: [] },
    owner: mockOwner,
    user_role: 'editor',
    collaborators_count: 0,
    updated_at: '2024-01-02T12:00:00Z',
    created_at: '2024-01-02T10:00:00Z'
  }
]

describe('NotesView', () => {
  let wrapper: any
  let authStore: any
  let toastStore: any

  beforeEach(() => {
    setActivePinia(createPinia())
    authStore = useAuthStore()
    toastStore = useToastStore()
    
    // Mock auth store
    authStore.user = {
      id: 1,
      name: 'Test User',
      email: 'test@example.com',
      avatar_url: null
    }
    // Don't set userName directly since it's computed
    authStore.logout = vi.fn().mockResolvedValue({ success: true })

    // Mock toast store
    toastStore.showToast = vi.fn()

    // Reset API mocks
    vi.mocked(apiService.getNotes).mockResolvedValue({
      data: { notes: mockNotes }
    })
    vi.mocked(apiService.createNote).mockResolvedValue({
      data: {
        note: {
          id: 3,
          title: 'New Note',
          content: { type: 'doc', content: [] },
          owner: mockOwner,
          user_role: 'owner',
          collaborators_count: 0,
          updated_at: '2024-01-03T12:00:00Z',
          created_at: '2024-01-03T12:00:00Z'
        },
        message: 'Note created successfully!'
      }
    })
    vi.mocked(apiService.deleteNote).mockResolvedValue({ data: {} })
    vi.mocked(apiService.getCollaborations).mockResolvedValue({ data: { collaborations: [] } })
  })

  describe('Component Initialization', () => {
    it('loads notes on mount', async () => {
      wrapper = mount(NotesView, {
        global: {
          plugins: [router]
        }
      })

      await wrapper.vm.$nextTick()
      expect(apiService.getNotes).toHaveBeenCalled()
    })

    it('displays navigation with correct user info', async () => {
      wrapper = mount(NotesView, {
        global: {
          plugins: [router]
        }
      })

      await wrapper.vm.$nextTick()
      expect(wrapper.text()).toContain('CollabNotes')
      expect(wrapper.find('.avatar img').exists()).toBe(true)
    })
  })

  describe('Search Functionality', () => {
    beforeEach(async () => {
      wrapper = mount(NotesView, {
        global: {
          plugins: [router]
        }
      })
      await wrapper.vm.$nextTick()
    })

    it('updates search query when input changes', async () => {
      const searchInput = wrapper.find('input[placeholder="Search notes..."]')
      await searchInput.setValue('Test')
      
      expect(wrapper.vm.searchQuery).toBe('Test')
    })

    it('passes search query to NotesList component', async () => {
      const searchInput = wrapper.find('input[placeholder="Search notes..."]')
      await searchInput.setValue('Test')
      
      const notesList = wrapper.findComponent({ name: 'NotesList' })
      expect(notesList.props('searchQuery')).toBe('Test')
    })
  })

  describe('Note Creation', () => {
    beforeEach(async () => {
      wrapper = mount(NotesView, {
        global: {
          plugins: [router]
        }
      })
      await wrapper.vm.$nextTick()
    })

    it('shows create modal when new note button clicked', async () => {
      const newNoteButton = wrapper.find('.btn-primary')
      await newNoteButton.trigger('click')
      
      expect(wrapper.find('.modal-open').exists()).toBe(true)
      expect(wrapper.text()).toContain('Create New Note')
    })

    it('creates note when form submitted', async () => {
      // Open modal
      const newNoteButton = wrapper.find('.btn-primary')
      await newNoteButton.trigger('click')
      
      // Fill form
      const titleInput = wrapper.find('input[placeholder="Enter note title..."]')
      await titleInput.setValue('New Test Note')
      
      // Submit form
      const form = wrapper.find('form')
      await form.trigger('submit')
      
      expect(apiService.createNote).toHaveBeenCalledWith({
        note: {
          title: 'New Test Note',
          content: { type: 'doc', content: [] },
          document_state: { version: 1, operations: [] }
        }
      })
    })

    it('shows success toast and navigates after creation', async () => {
      const pushSpy = vi.spyOn(router, 'push')
      
      // Open modal and create note
      await wrapper.find('.btn-primary').trigger('click')
      await wrapper.find('input[placeholder="Enter note title..."]').setValue('New Test Note')
      await wrapper.find('form').trigger('submit')
      
      await wrapper.vm.$nextTick()
      
      expect(toastStore.showToast).toHaveBeenCalledWith('Note created successfully!', 'success')
      expect(pushSpy).toHaveBeenCalledWith('/notes/3')
    })

    it('handles creation errors', async () => {
      vi.mocked(apiService.createNote).mockRejectedValue({
        response: { data: { error: 'Creation failed' } }
      })
      
      // Open modal and create note
      await wrapper.find('.btn-primary').trigger('click')
      await wrapper.find('input[placeholder="Enter note title..."]').setValue('New Test Note')
      await wrapper.find('form').trigger('submit')
      
      await wrapper.vm.$nextTick()
      
      expect(toastStore.showToast).toHaveBeenCalledWith('Creation failed', 'error')
    })
  })

  describe('Note Management', () => {
    beforeEach(async () => {
      wrapper = mount(NotesView, {
        global: {
          plugins: [router]
        }
      })
      await wrapper.vm.$nextTick()
    })

    it('navigates to note when open-note event emitted', async () => {
      const pushSpy = vi.spyOn(router, 'push')
      const notesList = wrapper.findComponent({ name: 'NotesList' })
      
      await notesList.vm.$emit('open-note', 1)
      
      expect(pushSpy).toHaveBeenCalledWith('/notes/1')
    })

    it('deletes note when delete-note event emitted', async () => {
      const notesList = wrapper.findComponent({ name: 'NotesList' })
      
      await notesList.vm.$emit('delete-note', mockNotes[0])
      
      expect(apiService.deleteNote).toHaveBeenCalledWith(mockNotes[0].id)
      expect(toastStore.showToast).toHaveBeenCalledWith('Note deleted successfully!', 'success')
    })

    it('handles delete errors', async () => {
      vi.mocked(apiService.deleteNote).mockRejectedValue({
        response: { data: { error: 'Delete failed' } }
      })
      
      const notesList = wrapper.findComponent({ name: 'NotesList' })
      await notesList.vm.$emit('delete-note', mockNotes[0])
      
      expect(toastStore.showToast).toHaveBeenCalledWith('Delete failed', 'error')
    })

    it('opens collaborators modal when manage-collaborators event emitted', async () => {
      const notesList = wrapper.findComponent({ name: 'NotesList' })
      
      await notesList.vm.$emit('manage-collaborators', mockNotes[0])
      
      expect(wrapper.vm.showCollaboratorsModal).toBe(true)
      expect(wrapper.vm.selectedNote).toEqual(mockNotes[0])
    })
  })

  describe('User Actions', () => {
    beforeEach(async () => {
      wrapper = mount(NotesView, {
        global: {
          plugins: [router]
        }
      })
      await wrapper.vm.$nextTick()
    })

    it('logs out user when logout clicked', async () => {
      const pushSpy = vi.spyOn(router, 'push')
      
      // Open user dropdown
      const dropdown = wrapper.find('.dropdown .avatar')
      await dropdown.trigger('click')
      
      // Click logout - find by text content
      const logoutLinks = wrapper.findAll('a')
      const logoutLink = logoutLinks.find((link: unknown) => link.text() === 'Logout')
      await logoutLink?.trigger('click')
      
      expect(authStore.logout).toHaveBeenCalled()
      expect(pushSpy).toHaveBeenCalledWith('/login')
    })
  })

  describe('Error Handling', () => {
    it('handles notes loading errors', async () => {
      vi.mocked(apiService.getNotes).mockRejectedValue(new Error('Network error'))
      
      wrapper = mount(NotesView, {
        global: {
          plugins: [router]
        }
      })
      
      await wrapper.vm.$nextTick()
      
      expect(toastStore.showToast).toHaveBeenCalledWith('Failed to load notes', 'error')
    })
  })
})