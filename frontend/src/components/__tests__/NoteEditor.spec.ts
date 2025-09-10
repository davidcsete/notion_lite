import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import NoteEditor from '../NoteEditor.vue'
import { useAuthStore } from '@/stores/auth'

// Mock the collaboration service
vi.mock('@/composables/useCollaborationService', () => ({
  useCollaborationService: () => ({
    connect: vi.fn().mockResolvedValue(undefined),
    disconnect: vi.fn(),
    sendOperation: vi.fn(),
    sendCursorUpdate: vi.fn(),
    sendTypingIndicator: vi.fn(),
    onReceiveOperation: vi.fn(),
    onUserJoin: vi.fn(),
    onUserLeave: vi.fn(),
    onCursorUpdate: vi.fn(),
    onTypingUpdate: vi.fn(),
    onConnectionStatusChange: vi.fn(),
    connectionStatus: { value: 'connected' }
  })
}))

// Mock document.execCommand
Object.defineProperty(document, 'execCommand', {
  value: vi.fn(),
  writable: true
})

// Mock document.queryCommandState
Object.defineProperty(document, 'queryCommandState', {
  value: vi.fn().mockReturnValue(false),
  writable: true
})

// Mock window.getSelection
Object.defineProperty(window, 'getSelection', {
  value: vi.fn(() => ({
    rangeCount: 1,
    getRangeAt: vi.fn(() => ({
      startContainer: document.createTextNode('test'),
      startOffset: 0,
      endContainer: document.createTextNode('test'),
      endOffset: 4,
      collapsed: false,
      deleteContents: vi.fn(),
      insertNode: vi.fn(),
      collapse: vi.fn()
    })),
    removeAllRanges: vi.fn(),
    addRange: vi.fn()
  })),
  writable: true
})

describe('NoteEditor', () => {
  let pinia: any

  beforeEach(() => {
    pinia = createPinia()
    setActivePinia(pinia)
    
    // Setup auth store
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      name: 'Test User',
      email: 'test@example.com'
    }
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  const defaultProps = {
    noteId: 1,
    initialContent: 'Test content',
    canEdit: true
  }

  it('renders correctly with initial content', () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    expect(wrapper.find('.note-editor').exists()).toBe(true)
    expect(wrapper.find('.editor-toolbar').exists()).toBe(true)
    expect(wrapper.find('[contenteditable="true"]').exists()).toBe(true)
  })

  it('shows read-only notice when canEdit is false', () => {
    const wrapper = mount(NoteEditor, {
      props: {
        ...defaultProps,
        canEdit: false
      },
      global: {
        plugins: [pinia]
      }
    })

    expect(wrapper.find('.alert-info').exists()).toBe(true)
    expect(wrapper.text()).toContain('You have view-only access to this note')
  })

  it('hides toolbar when canEdit is false', () => {
    const wrapper = mount(NoteEditor, {
      props: {
        ...defaultProps,
        canEdit: false
      },
      global: {
        plugins: [pinia]
      }
    })

    expect(wrapper.find('.editor-toolbar').exists()).toBe(false)
  })

  it('emits contentChange when content is modified', async () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any
    
    // Mock the editor element
    const mockElement = {
      innerText: 'New content',
      textContent: 'New content'
    }
    component.editorElement = mockElement

    // Simulate content change
    component.handleInput({ target: mockElement })

    // Check if contentChange event was emitted
    expect(wrapper.emitted('contentChange')).toBeTruthy()
  })

  it('prevents input when canEdit is false', async () => {
    const wrapper = mount(NoteEditor, {
      props: {
        ...defaultProps,
        canEdit: false
      },
      global: {
        plugins: [pinia]
      }
    })

    const editor = wrapper.find('[contenteditable="true"]')
    
    // Simulate input event
    const inputEvent = new Event('input', { bubbles: true })
    const preventDefaultSpy = vi.spyOn(inputEvent, 'preventDefault')
    
    await editor.element.dispatchEvent(inputEvent)

    expect(preventDefaultSpy).toHaveBeenCalled()
  })

  it('handles keyboard shortcuts correctly', async () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const editor = wrapper.find('[contenteditable="true"]')
    
    // Test Ctrl+B for bold
    await editor.trigger('keydown', {
      key: 'b',
      ctrlKey: true
    })

    expect(document.execCommand).toHaveBeenCalledWith('bold', false)
  })

  it('handles paste events correctly', async () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any
    
    // Create mock clipboard data
    const clipboardData = {
      getData: vi.fn().mockReturnValue('pasted text')
    }

    const pasteEvent = {
      preventDefault: vi.fn(),
      clipboardData
    }
    
    component.handlePaste(pasteEvent)

    expect(pasteEvent.preventDefault).toHaveBeenCalled()
    expect(clipboardData.getData).toHaveBeenCalledWith('text/plain')
  })

  it('formats text correctly', async () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    // Test bold button
    const boldButton = wrapper.find('button[title="Bold (Ctrl+B)"]')
    await boldButton.trigger('click')

    expect(document.execCommand).toHaveBeenCalledWith('bold', false)
  })

  it('inserts headings correctly', async () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    // Test H1 button
    const h1Button = wrapper.find('button[title="Heading 1"]')
    await h1Button.trigger('click')

    expect(document.execCommand).toHaveBeenCalledWith('formatBlock', false, 'h1')
  })

  it('inserts lists correctly', async () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    // Test bullet list button
    const listButton = wrapper.find('button[title="Bullet List"]')
    await listButton.trigger('click')

    expect(document.execCommand).toHaveBeenCalledWith('insertUnorderedList', false)
  })

  it('shows connection status correctly', () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any
    
    // Set connection status to connected
    component.connectionStatus = 'connected'
    
    // Wait for reactivity
    wrapper.vm.$nextTick(() => {
      // Should not show connection warning when connected
      expect(wrapper.find('.alert-warning').exists()).toBe(false)
    })
  })

  it('generates operations correctly for text insertion', async () => {
    const wrapper = mount(NoteEditor, {
      props: {
        ...defaultProps,
        initialContent: 'Hello'
      },
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any
    
    // Test insert operation
    const operation = component.generateOperation('Hello', 'Hello World')
    
    expect(operation).toEqual({
      type: 'insert',
      position: 5,
      content: ' World'
    })
  })

  it('generates operations correctly for text deletion', async () => {
    const wrapper = mount(NoteEditor, {
      props: {
        ...defaultProps,
        initialContent: 'Hello World'
      },
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any
    
    // Test delete operation
    const operation = component.generateOperation('Hello World', 'Hello')
    
    expect(operation).toEqual({
      type: 'delete',
      position: 5,
      length: 6
    })
  })

  it('applies operations correctly', async () => {
    const wrapper = mount(NoteEditor, {
      props: {
        ...defaultProps,
        initialContent: 'Hello'
      },
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any
    
    // Mock the editor element
    const mockElement = {
      innerText: 'Hello',
      innerHTML: 'Hello'
    }
    component.editorElement = mockElement

    // Test applying insert operation
    const insertOp = {
      type: 'insert',
      position: 5,
      content: ' World'
    }

    component.applyOperation(insertOp)

    expect(wrapper.emitted('contentChange')).toBeTruthy()
    expect(wrapper.emitted('contentChange')![0]).toEqual(['Hello World'])
  })

  it('handles typing indicators correctly', async () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any
    
    // Start typing
    component.handleTypingStart()
    expect(component.isTyping).toBe(true)

    // Stop typing
    component.handleTypingStop()
    expect(component.isTyping).toBe(false)
  })

  it('formats typing users correctly', () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any

    expect(component.formatTypingUsers(['Alice'])).toBe('Alice')
    expect(component.formatTypingUsers(['Alice', 'Bob'])).toBe('Alice and Bob')
    expect(component.formatTypingUsers(['Alice', 'Bob', 'Charlie'])).toBe('Alice, Bob and Charlie')
  })

  it('extracts text content correctly', () => {
    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as any

    // Mock element with text content
    const mockElement = {
      innerText: 'Hello World',
      textContent: 'Hello World'
    }

    const result = component.extractTextContent(mockElement)
    expect(result).toBe('Hello World')
  })

  it('debounces save operations correctly', async () => {
    vi.useFakeTimers()

    const wrapper = mount(NoteEditor, {
      props: defaultProps,
      global: {
        plugins: [pinia]
      }
    })

    const component = wrapper.vm as unknown
    
    // Call debouncedSave multiple times
    component.debouncedSave()
    component.debouncedSave()
    component.debouncedSave()

    // Fast-forward time
    vi.advanceTimersByTime(1000)

    // Should only emit save once
    expect(wrapper.emitted('save')).toBeTruthy()
    expect(wrapper.emitted('save')!.length).toBe(1)

    vi.useRealTimers()
  })
})