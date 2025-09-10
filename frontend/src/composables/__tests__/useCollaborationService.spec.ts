import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useCollaborationService } from '../useCollaborationService'
import { useAuthStore } from '@/stores/auth'

// Mock ActionCable
const mockSubscription = {
  send: vi.fn(),
  unsubscribe: vi.fn()
}

const mockCable = {
  subscriptions: {
    create: vi.fn().mockReturnValue(mockSubscription)
  },
  disconnect: vi.fn()
}

const mockActionCable = {
  createConsumer: vi.fn().mockReturnValue(mockCable)
}

// Mock window.ActionCable
Object.defineProperty(window, 'ActionCable', {
  value: mockActionCable,
  writable: true
})

// Mock toast store
vi.mock('@/stores/toast', () => ({
  useToastStore: () => ({
    showToast: vi.fn()
  })
}))

describe('useCollaborationService', () => {
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

    // Clear all mocks
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('initializes with disconnected status', () => {
    const { connectionStatus } = useCollaborationService()
    expect(connectionStatus.value).toBe('disconnected')
  })

  it('connects to WebSocket successfully', async () => {
    const { connect, connectionStatus } = useCollaborationService()

    // Mock successful connection
    const createSpy = vi.spyOn(mockCable.subscriptions, 'create').mockImplementation((params, callbacks) => {
      // Simulate successful connection
      setTimeout(() => callbacks.connected(), 0)
      return mockSubscription
    })

    const connectPromise = connect(1, 1)
    
    // Wait for connection
    await connectPromise

    expect(createSpy).toHaveBeenCalledWith(
      { channel: 'NoteChannel', note_id: 1 },
      expect.objectContaining({
        connected: expect.any(Function),
        disconnected: expect.any(Function),
        rejected: expect.any(Function),
        received: expect.any(Function)
      })
    )

    expect(connectionStatus.value).toBe('connected')
  })

  it('handles connection rejection', async () => {
    const { connect, connectionStatus } = useCollaborationService()

    // Mock connection rejection
    const createSpy = vi.spyOn(mockCable.subscriptions, 'create').mockImplementation((params, callbacks) => {
      setTimeout(() => callbacks.rejected(), 0)
      return mockSubscription
    })

    await expect(connect(1, 1)).rejects.toThrow('Connection rejected')
    expect(connectionStatus.value).toBe('error')
  })

  it('sends operations correctly', () => {
    const { sendOperation } = useCollaborationService()

    // Mock connected state
    const service = useCollaborationService()
    service.connectionStatus.value = 'connected' as any

    const operation = {
      type: 'insert' as const,
      position: 5,
      content: 'Hello'
    }

    sendOperation(operation)

    expect(mockSubscription.send).toHaveBeenCalledWith({
      type: 'operation',
      operation: {
        type: 'insert',
        position: 5,
        content: 'Hello',
        length: undefined,
        deleteLength: undefined
      },
      client_version: 0,
      timestamp: expect.any(String)
    })
  })

  it('sends cursor updates correctly', () => {
    const { sendCursorUpdate } = useCollaborationService()

    // Mock connected state
    const service = useCollaborationService()
    service.connectionStatus.value = 'connected' as any

    const cursorData = {
      position: 10,
      selection: { start: 5, end: 15 }
    }

    sendCursorUpdate(cursorData)

    expect(mockSubscription.send).toHaveBeenCalledWith({
      type: 'cursor',
      position: 10,
      selection: { start: 5, end: 15 }
    })
  })

  it('sends typing indicators correctly', () => {
    const { sendTypingIndicator } = useCollaborationService()

    // Mock connected state
    const service = useCollaborationService()
    service.connectionStatus.value = 'connected' as any

    sendTypingIndicator(true)

    expect(mockSubscription.send).toHaveBeenCalledWith({
      type: 'typing',
      is_typing: true
    })
  })

  it('handles received operations', () => {
    const { onReceiveOperation } = useCollaborationService()

    const operationCallback = vi.fn()
    onReceiveOperation(operationCallback)

    // Simulate receiving a message
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const operationData = {
      type: 'operation',
      operation: {
        type: 'insert',
        position: 5,
        content: 'Hello'
      },
      sender_id: 2 // Different from current user
    }

    handleReceivedMessage(operationData)

    expect(operationCallback).toHaveBeenCalledWith(operationData.operation)
  })

  it('ignores operations from current user', () => {
    const { onReceiveOperation } = useCollaborationService()

    const operationCallback = vi.fn()
    onReceiveOperation(operationCallback)

    // Simulate receiving a message from current user
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const operationData = {
      type: 'operation',
      operation: {
        type: 'insert',
        position: 5,
        content: 'Hello'
      },
      sender_id: 1 // Same as current user
    }

    handleReceivedMessage(operationData)

    expect(operationCallback).not.toHaveBeenCalled()
  })

  it('handles user join events', () => {
    const { onUserJoin } = useCollaborationService()

    const userJoinCallback = vi.fn()
    onUserJoin(userJoinCallback)

    // Simulate user join message
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const userData = {
      type: 'user_joined',
      user: {
        id: 2,
        name: 'Alice',
        email: 'alice@example.com'
      }
    }

    handleReceivedMessage(userData)

    expect(userJoinCallback).toHaveBeenCalledWith(userData.user)
  })

  it('handles user leave events', () => {
    const { onUserLeave } = useCollaborationService()

    const userLeaveCallback = vi.fn()
    onUserLeave(userLeaveCallback)

    // Simulate user leave message
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const userData = {
      type: 'user_left',
      user_id: 2
    }

    handleReceivedMessage(userData)

    expect(userLeaveCallback).toHaveBeenCalledWith(2)
  })

  it('handles cursor updates', () => {
    const { onCursorUpdate } = useCollaborationService()

    const cursorCallback = vi.fn()
    onCursorUpdate(cursorCallback)

    // Simulate cursor update message
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const cursorData = {
      type: 'cursor',
      user_id: 2,
      user_name: 'Alice',
      position: 10,
      selection: { start: 5, end: 15 }
    }

    handleReceivedMessage(cursorData)

    expect(cursorCallback).toHaveBeenCalledWith(
      2,
      'Alice',
      {
        position: 10,
        selection: { start: 5, end: 15 }
      }
    )
  })

  it('ignores cursor updates from current user', () => {
    const { onCursorUpdate } = useCollaborationService()

    const cursorCallback = vi.fn()
    onCursorUpdate(cursorCallback)

    // Simulate cursor update from current user
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const cursorData = {
      type: 'cursor',
      user_id: 1, // Same as current user
      user_name: 'Test User',
      position: 10
    }

    handleReceivedMessage(cursorData)

    expect(cursorCallback).not.toHaveBeenCalled()
  })

  it('handles typing indicators', () => {
    const { onTypingUpdate } = useCollaborationService()

    const typingCallback = vi.fn()
    onTypingUpdate(typingCallback)

    // Simulate typing indicator message
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const typingData = {
      type: 'typing',
      user_id: 2,
      user_name: 'Alice',
      is_typing: true
    }

    handleReceivedMessage(typingData)

    expect(typingCallback).toHaveBeenCalledWith(2, 'Alice', true)
  })

  it('disconnects properly', () => {
    const { connect, disconnect } = useCollaborationService()

    // First connect
    connect(1, 1)

    // Then disconnect
    disconnect()

    expect(mockSubscription.unsubscribe).toHaveBeenCalled()
    expect(mockCable.disconnect).toHaveBeenCalled()
  })

  it('does not send messages when disconnected', () => {
    const { sendOperation, connectionStatus } = useCollaborationService()

    // Ensure disconnected state
    expect(connectionStatus.value).toBe('disconnected')

    const operation = {
      type: 'insert' as const,
      position: 5,
      content: 'Hello'
    }

    sendOperation(operation)

    expect(mockSubscription.send).not.toHaveBeenCalled()
  })

  it('handles connection status changes', () => {
    const { onConnectionStatusChange } = useCollaborationService()

    const statusCallback = vi.fn()
    onConnectionStatusChange(statusCallback)

    // Simulate status change
    const service = useCollaborationService()
    const notifyConnectionStatusChange = (service as any).notifyConnectionStatusChange

    notifyConnectionStatusChange()

    expect(statusCallback).toHaveBeenCalledWith('disconnected')
  })

  it('schedules reconnection on disconnect', async () => {
    vi.useFakeTimers()

    const { connect } = useCollaborationService()

    // Mock connection that disconnects
    const createSpy = vi.spyOn(mockCable.subscriptions, 'create').mockImplementation((params, callbacks) => {
      // First connect successfully
      setTimeout(() => callbacks.connected(), 0)
      // Then disconnect
      setTimeout(() => callbacks.disconnected(), 100)
      return mockSubscription
    })

    await connect(1, 1)

    // Fast-forward to trigger reconnection
    vi.advanceTimersByTime(2000)

    // Should attempt to reconnect
    expect(createSpy).toHaveBeenCalledTimes(2)

    vi.useRealTimers()
  })

  it('handles operation acknowledgments', () => {
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const ackData = {
      type: 'operation_ack',
      operation_id: 123,
      new_version: 5
    }

    // Should not throw error
    expect(() => handleReceivedMessage(ackData)).not.toThrow()
  })

  it('handles operation errors', () => {
    const service = useCollaborationService()
    const handleReceivedMessage = (service as any).handleReceivedMessage

    const errorData = {
      type: 'operation_error',
      error: 'Invalid operation',
      operation: { type: 'insert', position: 5 }
    }

    // Should not throw error
    expect(() => handleReceivedMessage(errorData)).not.toThrow()
  })
})