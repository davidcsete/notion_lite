import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import NotesList from '../NotesList.vue'
import type { Note } from '@/services/api'

// Mock data
const mockOwner = {
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  avatar_url: undefined
}

const mockNotes: Note[] = [
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
  },
  {
    id: 3,
    title: 'Another Note',
    content: { type: 'doc', content: [] },
    owner: mockOwner,
    user_role: 'viewer',
    collaborators_count: 1,
    updated_at: '2024-01-03T12:00:00Z',
    created_at: '2024-01-03T10:00:00Z'
  }
]

describe('NotesList', () => {
  let wrapper: any

  beforeEach(() => {
    // Mock window.confirm
    vi.stubGlobal('confirm', vi.fn(() => true))
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  describe('Loading State', () => {
    it('displays loading spinner when loading is true', () => {
      wrapper = mount(NotesList, {
        props: {
          notes: [],
          loading: true,
          searchQuery: ''
        }
      })

      expect(wrapper.find('.loading-spinner').exists()).toBe(true)
      expect(wrapper.find('.grid').exists()).toBe(false)
    })
  })

  describe('Notes Display', () => {
    beforeEach(() => {
      wrapper = mount(NotesList, {
        props: {
          notes: mockNotes,
          loading: false,
          searchQuery: ''
        }
      })
    })

    it('displays all notes when not loading', () => {
      expect(wrapper.find('.loading-spinner').exists()).toBe(false)
      expect(wrapper.findAll('.card').length).toBe(3)
    })

    it('displays note titles correctly', () => {
      const cards = wrapper.findAll('.card')
      expect(cards[0].find('.card-title').text()).toBe('Test Note 1')
      expect(cards[1].find('.card-title').text()).toBe('Test Note 2')
      expect(cards[2].find('.card-title').text()).toBe('Another Note')
    })

    it('displays user roles as badges', () => {
      const badges = wrapper.findAll('.badge-outline')
      expect(badges[0].text()).toBe('owner')
      expect(badges[1].text()).toBe('editor')
      expect(badges[2].text()).toBe('viewer')
    })

    it('displays collaborator count when present', () => {
      const collaboratorBadges = wrapper.findAll('.badge-secondary')
      expect(collaboratorBadges[0].text()).toBe('2 collaborators')
      expect(collaboratorBadges[1].text()).toBe('1 collaborator')
    })

    it('does not display collaborator badge when count is 0', () => {
      const cards = wrapper.findAll('.card')
      const secondCard = cards[1]
      expect(secondCard.find('.badge-secondary').exists()).toBe(false)
    })
  })

  describe('Search Functionality', () => {
    beforeEach(() => {
      wrapper = mount(NotesList, {
        props: {
          notes: mockNotes,
          loading: false,
          searchQuery: 'Test'
        }
      })
    })

    it('filters notes based on search query', () => {
      expect(wrapper.findAll('.card').length).toBe(2)
      const titles = wrapper.findAll('.card-title').map((el: any) => el.text())
      expect(titles).toEqual(['Test Note 1', 'Test Note 2'])
    })

    it('shows empty state with search message when no matches', async () => {
      await wrapper.setProps({ searchQuery: 'NonExistent' })
      
      expect(wrapper.findAll('.card').length).toBe(1) // Empty state card
      expect(wrapper.text()).toContain('No notes match your search criteria')
    })
  })

  describe('Empty State', () => {
    beforeEach(() => {
      wrapper = mount(NotesList, {
        props: {
          notes: [],
          loading: false,
          searchQuery: ''
        }
      })
    })

    it('displays empty state when no notes', () => {
      expect(wrapper.text()).toContain('No notes found')
      expect(wrapper.text()).toContain('Create your first note to get started')
      expect(wrapper.find('.btn-primary').exists()).toBe(true)
    })

    it('emits create-note event when create button clicked', async () => {
      await wrapper.find('.btn-primary').trigger('click')
      expect(wrapper.emitted('create-note')).toBeTruthy()
    })
  })

  describe('Note Actions', () => {
    beforeEach(() => {
      wrapper = mount(NotesList, {
        props: {
          notes: mockNotes,
          loading: false,
          searchQuery: ''
        }
      })
    })

    it('emits open-note event when open button clicked', async () => {
      const openButton = wrapper.find('.btn-primary')
      await openButton.trigger('click')
      
      expect(wrapper.emitted('open-note')).toBeTruthy()
      expect(wrapper.emitted('open-note')[0]).toEqual([1])
    })

    it('emits open-note event when dropdown open action clicked', async () => {
      // Click dropdown trigger
      const dropdown = wrapper.find('.dropdown .btn-circle')
      await dropdown.trigger('click')
      
      // Click open action
      const openAction = wrapper.find('.dropdown-content li:first-child a')
      await openAction.trigger('click')
      
      expect(wrapper.emitted('open-note')).toBeTruthy()
      expect(wrapper.emitted('open-note')[0]).toEqual([1])
    })

    it('shows manage collaborators option only for owners', () => {
      const dropdowns = wrapper.findAll('.dropdown-content')
      
      // First note (owner) should have manage collaborators option
      expect(dropdowns[0].text()).toContain('Manage Collaborators')
      
      // Second note (editor) should not have manage collaborators option
      expect(dropdowns[1].text()).not.toContain('Manage Collaborators')
      
      // Third note (viewer) should not have manage collaborators option
      expect(dropdowns[2].text()).not.toContain('Manage Collaborators')
    })

    it('shows delete option only for owners', () => {
      const dropdowns = wrapper.findAll('.dropdown-content')
      
      // First note (owner) should have delete option
      expect(dropdowns[0].text()).toContain('Delete')
      
      // Second note (editor) should not have delete option
      expect(dropdowns[1].text()).not.toContain('Delete')
      
      // Third note (viewer) should not have delete option
      expect(dropdowns[2].text()).not.toContain('Delete')
    })

    it('emits manage-collaborators event when manage collaborators clicked', async () => {
      const dropdown = wrapper.find('.dropdown .btn-circle')
      await dropdown.trigger('click')
      
      const manageAction = wrapper.find('.dropdown-content li:nth-child(2) a')
      await manageAction.trigger('click')
      
      expect(wrapper.emitted('manage-collaborators')).toBeTruthy()
      expect(wrapper.emitted('manage-collaborators')[0]).toEqual([mockNotes[0]])
    })

    it('shows confirmation dialog and emits delete-note event when delete clicked', async () => {
      const confirmSpy = vi.fn(() => true)
      vi.stubGlobal('confirm', confirmSpy)
      
      const dropdown = wrapper.find('.dropdown .btn-circle')
      await dropdown.trigger('click')
      
      const deleteAction = wrapper.find('.dropdown-content .text-error')
      await deleteAction.trigger('click')
      
      expect(confirmSpy).toHaveBeenCalledWith('Are you sure you want to delete this note? This action cannot be undone.')
      expect(wrapper.emitted('delete-note')).toBeTruthy()
      expect(wrapper.emitted('delete-note')[0]).toEqual([mockNotes[0]])
    })

    it('does not emit delete-note event when confirmation is cancelled', async () => {
      const confirmSpy = vi.fn(() => false)
      vi.stubGlobal('confirm', confirmSpy)
      
      const dropdown = wrapper.find('.dropdown .btn-circle')
      await dropdown.trigger('click')
      
      const deleteAction = wrapper.find('.dropdown-content .text-error')
      await deleteAction.trigger('click')
      
      expect(confirmSpy).toHaveBeenCalled()
      expect(wrapper.emitted('delete-note')).toBeFalsy()
    })
  })

  describe('Date Formatting', () => {
    it('formats recent dates correctly', () => {
      const now = new Date()
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000)
      const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)
      
      const recentNotes = [
        {
          ...mockNotes[0],
          updated_at: oneHourAgo.toISOString()
        },
        {
          ...mockNotes[1],
          updated_at: oneDayAgo.toISOString()
        }
      ]
      
      wrapper = mount(NotesList, {
        props: {
          notes: recentNotes,
          loading: false,
          searchQuery: ''
        }
      })
      
      const dateTexts = wrapper.findAll('.text-base-content\\/60').map((el: unknown) => el.text())
      expect(dateTexts[0]).toContain('hour')
      expect(dateTexts[1]).toContain('day')
    })
  })
})