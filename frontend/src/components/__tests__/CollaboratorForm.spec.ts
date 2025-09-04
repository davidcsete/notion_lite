import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import CollaboratorForm from '../CollaboratorForm.vue'
import { apiService } from '@/services/api'

// Mock the API service
vi.mock('@/services/api', () => ({
  apiService: {
    searchUsers: vi.fn()
  }
}))

describe('CollaboratorForm', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders form elements correctly', () => {
    const wrapper = mount(CollaboratorForm)
    
    expect(wrapper.find('input[type="email"]').exists()).toBe(true)
    expect(wrapper.find('select').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  it('emits submit event with correct data', async () => {
    const wrapper = mount(CollaboratorForm)
    
    await wrapper.find('input[type="email"]').setValue('test@example.com')
    await wrapper.find('select').setValue('editor')
    await wrapper.find('form').trigger('submit.prevent')
    
    expect(wrapper.emitted('submit')).toBeTruthy()
    expect(wrapper.emitted('submit')?.[0]).toEqual([{
      email: 'test@example.com',
      role: 'editor'
    }])
  })

  it('resets form after submission', async () => {
    const wrapper = mount(CollaboratorForm)
    
    await wrapper.find('input[type="email"]').setValue('test@example.com')
    await wrapper.find('select').setValue('editor')
    await wrapper.find('form').trigger('submit.prevent')
    
    expect(wrapper.find('input[type="email"]').element.value).toBe('')
    expect(wrapper.find('select').element.value).toBe('viewer')
  })

  it('shows loading state when loading prop is true', () => {
    const wrapper = mount(CollaboratorForm, {
      props: { loading: true }
    })
    
    expect(wrapper.find('.loading-spinner').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').attributes('disabled')).toBeDefined()
  })

  it('applies compact variant classes correctly', () => {
    const wrapper = mount(CollaboratorForm, {
      props: { variant: 'compact' }
    })
    
    expect(wrapper.find('form').classes()).toContain('space-y-2')
    expect(wrapper.find('input').classes()).toContain('input-sm')
    expect(wrapper.find('select').classes()).toContain('select-sm')
    expect(wrapper.find('button').classes()).toContain('btn-sm')
  })

  it('triggers search when typing in email field', async () => {
    const mockSearchResponse = {
      data: {
        users: [
          { id: 1, name: 'John Doe', email: 'john@example.com' },
          { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
        ]
      }
    }
    
    vi.mocked(apiService.searchUsers).mockResolvedValue(mockSearchResponse)
    
    const wrapper = mount(CollaboratorForm)
    const input = wrapper.find('input[type="email"]')
    
    await input.setValue('john')
    await input.trigger('input')
    
    // Wait for debounce
    await new Promise(resolve => setTimeout(resolve, 350))
    
    expect(apiService.searchUsers).toHaveBeenCalledWith('john')
  })

  it('shows search results dropdown', async () => {
    const mockSearchResponse = {
      data: {
        users: [
          { id: 1, name: 'John Doe', email: 'john@example.com' }
        ]
      }
    }
    
    vi.mocked(apiService.searchUsers).mockResolvedValue(mockSearchResponse)
    
    const wrapper = mount(CollaboratorForm)
    const input = wrapper.find('input[type="email"]')
    
    await input.setValue('john')
    await input.trigger('input')
    await input.trigger('focus')
    
    // Wait for debounce and API call
    await new Promise(resolve => setTimeout(resolve, 350))
    await wrapper.vm.$nextTick()
    
    expect(wrapper.find('.absolute.z-50').exists()).toBe(true)
  })

  it('selects user from search results', async () => {
    const mockSearchResponse = {
      data: {
        users: [
          { id: 1, name: 'John Doe', email: 'john@example.com' }
        ]
      }
    }
    
    vi.mocked(apiService.searchUsers).mockResolvedValue(mockSearchResponse)
    
    const wrapper = mount(CollaboratorForm)
    const input = wrapper.find('input[type="email"]')
    
    await input.setValue('john')
    await input.trigger('input')
    await input.trigger('focus')
    
    // Wait for debounce and API call
    await new Promise(resolve => setTimeout(resolve, 350))
    await wrapper.vm.$nextTick()
    
    // Click on the search result
    const searchResult = wrapper.find('button[type="button"]')
    await searchResult.trigger('mousedown')
    
    expect(input.element.value).toBe('john@example.com')
  })
})