import { ref, onUnmounted, readonly } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'

interface Operation {
  type: 'insert' | 'delete' | 'replace'
  position: number
  content?: string
  length?: number
  deleteLength?: number
}

interface CursorData {
  position: number
  selection?: { start: number; end: number }
}

interface User {
  id: number
  name: string
  email: string
  avatar_url?: string
}

type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'error'

export function useCollaborationService() {
  const authStore = useAuthStore()
  const toastStore = useToastStore()

  // State
  const cable = ref<any>(null)
  const subscription = ref<any>(null)
  const connectionStatus = ref<ConnectionStatus>('disconnected')
  const reconnectAttempts = ref(0)
  const maxReconnectAttempts = 5
  const reconnectTimeout = ref<number | null>(null)

  // Event callbacks
  const operationCallbacks = ref<Array<(operation: any) => void>>([])
  const userJoinCallbacks = ref<Array<(user: User) => void>>([])
  const userLeaveCallbacks = ref<Array<(userId: number) => void>>([])
  const cursorUpdateCallbacks = ref<Array<(userId: number, userName: string, cursorData: CursorData) => void>>([])
  const typingUpdateCallbacks = ref<Array<(userId: number, userName: string, isTyping: boolean) => void>>([])
  const connectionStatusCallbacks = ref<Array<(status: ConnectionStatus) => void>>([])

  // ActionCable connection
  const createCableConnection = () => {
    if (typeof window === 'undefined') return null

    // Import ActionCable dynamically
    const ActionCable = (window as any).ActionCable || require('@rails/actioncable')
    
    const wsUrl = import.meta.env.VITE_WS_URL || 'ws://localhost:3000/cable'
    
    return ActionCable.createConsumer(wsUrl)
  }

  const connect = async (noteId: number, userId: number): Promise<void> => {
    return new Promise((resolve, reject) => {
      try {
        connectionStatus.value = 'connecting'
        notifyConnectionStatusChange()

        // Create cable connection if not exists
        if (!cable.value) {
          cable.value = createCableConnection()
        }

        // Subscribe to note channel
        subscription.value = cable.value.subscriptions.create(
          {
            channel: 'NoteChannel',
            note_id: noteId
          },
          {
            connected() {
              console.log('Connected to NoteChannel')
              connectionStatus.value = 'connected'
              reconnectAttempts.value = 0
              notifyConnectionStatusChange()
              resolve()
            },

            disconnected() {
              console.log('Disconnected from NoteChannel')
              connectionStatus.value = 'disconnected'
              notifyConnectionStatusChange()
              
              // Attempt to reconnect
              scheduleReconnect(noteId, userId)
            },

            rejected() {
              console.log('Subscription rejected')
              connectionStatus.value = 'error'
              notifyConnectionStatusChange()
              reject(new Error('Connection rejected'))
            },

            received(data: any) {
              handleReceivedMessage(data)
            }
          }
        )

        // Set connection timeout
        setTimeout(() => {
          if (connectionStatus.value === 'connecting') {
            connectionStatus.value = 'error'
            notifyConnectionStatusChange()
            reject(new Error('Connection timeout'))
          }
        }, 10000)

      } catch (error) {
        console.error('Failed to connect:', error)
        connectionStatus.value = 'error'
        notifyConnectionStatusChange()
        reject(error)
      }
    })
  }

  const disconnect = () => {
    if (subscription.value) {
      subscription.value.unsubscribe()
      subscription.value = null
    }

    if (cable.value) {
      cable.value.disconnect()
      cable.value = null
    }

    if (reconnectTimeout.value) {
      clearTimeout(reconnectTimeout.value)
      reconnectTimeout.value = null
    }

    connectionStatus.value = 'disconnected'
    notifyConnectionStatusChange()
  }

  const scheduleReconnect = (noteId: number, userId: number) => {
    if (reconnectAttempts.value >= maxReconnectAttempts) {
      console.log('Max reconnection attempts reached')
      connectionStatus.value = 'error'
      notifyConnectionStatusChange()
      toastStore.showToast('Connection lost. Please refresh the page.', 'error')
      return
    }

    const delay = Math.min(1000 * Math.pow(2, reconnectAttempts.value), 30000)
    reconnectAttempts.value++

    console.log(`Scheduling reconnect attempt ${reconnectAttempts.value} in ${delay}ms`)

    reconnectTimeout.value = setTimeout(async () => {
      try {
        await connect(noteId, userId)
      } catch (error) {
        console.error('Reconnection failed:', error)
        scheduleReconnect(noteId, userId)
      }
    }, delay)
  }

  const handleReceivedMessage = (data: any) => {
    console.log('Received message:', data)

    switch (data.type) {
      case 'operation':
        handleOperationReceived(data)
        break
      case 'user_joined':
        handleUserJoined(data)
        break
      case 'user_left':
        handleUserLeft(data)
        break
      case 'cursor':
        handleCursorUpdate(data)
        break
      case 'typing':
        handleTypingUpdate(data)
        break
      case 'operation_ack':
        handleOperationAck(data)
        break
      case 'operation_error':
        handleOperationError(data)
        break
      default:
        console.log('Unknown message type:', data.type)
    }
  }

  const handleOperationReceived = (data: any) => {
    // Don't apply operations from the current user
    if (data.sender_id === authStore.user?.id) {
      return
    }

    const operation = data.operation
    operationCallbacks.value.forEach(callback => callback(operation))
  }

  const handleUserJoined = (data: any) => {
    const user = data.user
    userJoinCallbacks.value.forEach(callback => callback(user))
  }

  const handleUserLeft = (data: any) => {
    const userId = data.user_id
    userLeaveCallbacks.value.forEach(callback => callback(userId))
  }

  const handleCursorUpdate = (data: any) => {
    // Don't show cursor updates from the current user
    if (data.user_id === authStore.user?.id) {
      return
    }

    const cursorData = {
      position: data.position,
      selection: data.selection
    }

    cursorUpdateCallbacks.value.forEach(callback => 
      callback(data.user_id, data.user_name, cursorData)
    )
  }

  const handleTypingUpdate = (data: any) => {
    // Don't show typing indicators from the current user
    if (data.user_id === authStore.user?.id) {
      return
    }

    typingUpdateCallbacks.value.forEach(callback => 
      callback(data.user_id, data.user_name, data.is_typing)
    )
  }

  const handleOperationAck = (data: any) => {
    console.log('Operation acknowledged:', data)
    // Handle operation acknowledgment if needed
  }

  const handleOperationError = (data: any) => {
    console.error('Operation error:', data)
    toastStore.showToast(`Operation failed: ${data.error}`, 'error')
  }

  const sendOperation = (operation: Operation) => {
    if (!subscription.value || connectionStatus.value !== 'connected') {
      console.warn('Cannot send operation: not connected')
      return
    }

    const message = {
      type: 'operation',
      operation: {
        type: operation.type,
        position: operation.position,
        content: operation.content,
        length: operation.length,
        deleteLength: operation.deleteLength
      },
      client_version: 0, // TODO: Implement proper versioning
      timestamp: new Date().toISOString()
    }

    subscription.value.send(message)
  }

  const sendCursorUpdate = (cursorData: CursorData) => {
    if (!subscription.value || connectionStatus.value !== 'connected') {
      return
    }

    const message = {
      type: 'cursor',
      position: cursorData.position,
      selection: cursorData.selection
    }

    subscription.value.send(message)
  }

  const sendTypingIndicator = (isTyping: boolean) => {
    if (!subscription.value || connectionStatus.value !== 'connected') {
      return
    }

    const message = {
      type: 'typing',
      is_typing: isTyping
    }

    subscription.value.send(message)
  }

  const requestSync = () => {
    if (!subscription.value || connectionStatus.value !== 'connected') {
      return
    }

    const message = {
      type: 'sync_request',
      client_version: 0 // TODO: Implement proper versioning
    }

    subscription.value.send(message)
  }

  // Event subscription methods
  const onReceiveOperation = (callback: (operation: any) => void) => {
    operationCallbacks.value.push(callback)
  }

  const onUserJoin = (callback: (user: User) => void) => {
    userJoinCallbacks.value.push(callback)
  }

  const onUserLeave = (callback: (userId: number) => void) => {
    userLeaveCallbacks.value.push(callback)
  }

  const onCursorUpdate = (callback: (userId: number, userName: string, cursorData: CursorData) => void) => {
    cursorUpdateCallbacks.value.push(callback)
  }

  const onTypingUpdate = (callback: (userId: number, userName: string, isTyping: boolean) => void) => {
    typingUpdateCallbacks.value.push(callback)
  }

  const onConnectionStatusChange = (callback: (status: ConnectionStatus) => void) => {
    connectionStatusCallbacks.value.push(callback)
  }

  const notifyConnectionStatusChange = () => {
    connectionStatusCallbacks.value.forEach(callback => callback(connectionStatus.value))
  }

  // Cleanup on unmount
  onUnmounted(() => {
    disconnect()
  })

  return {
    // Connection methods
    connect,
    disconnect,
    requestSync,

    // Sending methods
    sendOperation,
    sendCursorUpdate,
    sendTypingIndicator,

    // Event subscription methods
    onReceiveOperation,
    onUserJoin,
    onUserLeave,
    onCursorUpdate,
    onTypingUpdate,
    onConnectionStatusChange,

    // State
    connectionStatus: readonly(connectionStatus)
  }
}

// Helper function to check if ActionCable is available
export const isActionCableAvailable = (): boolean => {
  if (typeof window === 'undefined') return false
  
  return !!(window as any).ActionCable || 
         (typeof require !== 'undefined' && require('@rails/actioncable'))
}

// Helper function to load ActionCable dynamically
export const loadActionCable = async (): Promise<void> => {
  if (isActionCableAvailable()) return

  try {
    // Try to load from CDN if not available
    const script = document.createElement('script')
    script.src = 'https://unpkg.com/@rails/actioncable@7.0.0/app/assets/javascripts/actioncable.js'
    
    return new Promise((resolve, reject) => {
      script.onload = () => resolve()
      script.onerror = () => reject(new Error('Failed to load ActionCable'))
      document.head.appendChild(script)
    })
  } catch (error) {
    console.error('Failed to load ActionCable:', error)
    throw error
  }
}