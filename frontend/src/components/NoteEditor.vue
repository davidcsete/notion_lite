<template>
  <div class="note-editor" ref="editorContainer">
    <!-- Editor Toolbar -->
    <div v-if="canEdit" class="editor-toolbar flex flex-wrap gap-2 mb-4 pb-4 border-b border-base-300">
      <div class="btn-group">
        <button 
          @click="formatText('bold')"
          :class="['btn btn-sm btn-outline', { 'btn-active': isFormatActive('bold') }]"
          title="Bold (Ctrl+B)"
        >
          <strong>B</strong>
        </button>
        <button 
          @click="formatText('italic')"
          :class="['btn btn-sm btn-outline', { 'btn-active': isFormatActive('italic') }]"
          title="Italic (Ctrl+I)"
        >
          <em>I</em>
        </button>
        <button 
          @click="formatText('underline')"
          :class="['btn btn-sm btn-outline', { 'btn-active': isFormatActive('underline') }]"
          title="Underline (Ctrl+U)"
        >
          <u>U</u>
        </button>
      </div>
      
      <div class="divider divider-horizontal"></div>
      
      <div class="btn-group">
        <button 
          @click="insertHeading(1)"
          class="btn btn-sm btn-outline"
          title="Heading 1"
        >
          H1
        </button>
        <button 
          @click="insertHeading(2)"
          class="btn btn-sm btn-outline"
          title="Heading 2"
        >
          H2
        </button>
        <button 
          @click="insertList('bullet')"
          class="btn btn-sm btn-outline"
          title="Bullet List"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Connection Status -->
    <div v-if="connectionStatus !== 'connected'" class="alert alert-warning mb-4">
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
      </svg>
      <span>
        {{ connectionStatus === 'connecting' ? 'Connecting...' : 
           connectionStatus === 'disconnected' ? 'Disconnected - Changes will be saved locally' :
           'Connection error - Retrying...' }}
      </span>
    </div>

    <!-- Read-only notice -->
    <div v-if="!canEdit" class="alert alert-info mb-4">
      <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>
      <span>You have view-only access to this note.</span>
    </div>

    <!-- Editor Area -->
    <div class="editor-content relative">
      <div
        ref="editorElement"
        class="editor-textarea min-h-96 p-4 text-lg leading-relaxed focus:outline-none"
        :class="{ 'cursor-not-allowed opacity-60': !canEdit }"
        contenteditable="true"
        @input="handleInput"
        @keydown="handleKeyDown"
        @keyup="handleKeyUp"
        @mouseup="handleSelectionChange"
        @focus="handleFocus"
        @blur="handleBlur"
        @paste="handlePaste"
      ></div>

      <!-- Collaborator Cursors -->
      <div 
        v-for="cursor in collaboratorCursors" 
        :key="cursor.userId"
        class="absolute pointer-events-none"
        :style="cursor.style"
      >
        <div 
          class="w-0.5 h-5 animate-pulse"
          :style="{ backgroundColor: cursor.color }"
        ></div>
        <div 
          class="absolute -top-6 left-0 px-2 py-1 text-xs text-white rounded whitespace-nowrap"
          :style="{ backgroundColor: cursor.color }"
        >
          {{ cursor.userName }}
        </div>
      </div>
    </div>

    <!-- Active Collaborators -->
    <div v-if="activeUsers.length > 1" class="mt-4 flex items-center gap-2">
      <span class="text-sm opacity-60">Active collaborators:</span>
      <div class="flex -space-x-2">
        <div
          v-for="user in activeUsers.filter(u => u.id !== currentUserId)"
          :key="user.id"
          class="avatar"
          :title="user.name"
        >
          <div class="w-8 rounded-full ring-2 ring-base-100">
            <img 
              :src="user.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random`"
              :alt="user.name"
            />
          </div>
        </div>
      </div>
      <div v-if="typingUsers.length > 0" class="text-sm opacity-60 ml-2">
        {{ formatTypingUsers(typingUsers) }} typing...
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import { useCollaborationService } from '@/composables/useCollaborationService'

interface Props {
  noteId: number
  initialContent: string
  canEdit: boolean
}

interface User {
  id: number
  name: string
  email: string
  avatar_url?: string
}

interface CollaboratorCursor {
  userId: number
  userName: string
  position: number
  selection?: { start: number; end: number }
  color: string
  style: Record<string, string>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  contentChange: [content: string]
  save: [content: string]
}>()

const authStore = useAuthStore()
const toastStore = useToastStore()

// Template refs
const editorContainer = ref<HTMLElement>()
const editorElement = ref<HTMLElement>()

// Editor state
const content = ref('')
const isTyping = ref(false)
const typingTimeout = ref<number | null>(null)
const saveTimeout = ref<number | null>(null)

// Collaboration state
const activeUsers = ref<User[]>([])
const collaboratorCursors = ref<CollaboratorCursor[]>([])
const typingUsers = ref<string[]>([])

// Connection state
const connectionStatus = ref<'connecting' | 'connected' | 'disconnected' | 'error'>('connecting')

// Collaboration service
const {
  connect,
  disconnect,
  sendOperation,
  sendCursorUpdate,
  sendTypingIndicator,
  onReceiveOperation,
  onUserJoin,
  onUserLeave,
  onCursorUpdate,
  onTypingUpdate,
  onConnectionStatusChange
} = useCollaborationService()

// Computed
const currentUserId = computed(() => authStore.user?.id)

// User colors for cursors (deterministic based on user ID)
const getUserColor = (userId: number): string => {
  const colors = [
    '#ef4444', '#f97316', '#eab308', '#22c55e', 
    '#06b6d4', '#3b82f6', '#8b5cf6', '#ec4899'
  ]
  return colors[userId % colors.length]
}

// Methods
const initializeEditor = async () => {
  if (!editorElement.value) return

  // Set initial content
  content.value = props.initialContent
  editorElement.value.innerHTML = formatContentForDisplay(props.initialContent)

  // Connect to collaboration service
  if (props.noteId) {
    try {
      await connect(props.noteId, currentUserId.value!)
      connectionStatus.value = 'connected'
    } catch (error) {
      console.error('Failed to connect to collaboration service:', error)
      connectionStatus.value = 'error'
      toastStore.showToast('Failed to connect to real-time collaboration', 'error')
    }
  }
}

const formatContentForDisplay = (text: string): string => {
  // Convert plain text to HTML with basic formatting
  return text
    .replace(/\n/g, '<br>')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
}

const extractTextContent = (element: HTMLElement): string => {
  // Extract plain text from HTML, preserving line breaks
  return element.innerText || element.textContent || ''
}

const handleInput = (event: Event) => {
  if (!props.canEdit) {
    event.preventDefault()
    return
  }

  const target = event.target as HTMLElement
  const newContent = extractTextContent(target)
  
  if (newContent !== content.value) {
    const oldContent = content.value
    content.value = newContent

    // Generate and send operation
    const operation = generateOperation(oldContent, newContent)
    if (operation) {
      sendOperation(operation)
    }

    // Emit content change
    emit('contentChange', newContent)

    // Handle typing indicator
    handleTypingStart()

    // Debounced save
    debouncedSave()
  }
}

const generateOperation = (oldText: string, newText: string) => {
  // Simple diff algorithm to generate operations
  // In a production app, you'd use a more sophisticated diff algorithm
  
  let position = 0
  let i = 0
  
  // Find the first difference
  while (i < Math.min(oldText.length, newText.length) && oldText[i] === newText[i]) {
    i++
  }
  position = i

  if (oldText.length === newText.length && position === oldText.length) {
    return null // No changes
  }

  // Determine operation type
  if (newText.length > oldText.length) {
    // Insert operation
    const insertedText = newText.slice(position, position + (newText.length - oldText.length))
    return {
      type: 'insert',
      position,
      content: insertedText
    }
  } else if (newText.length < oldText.length) {
    // Delete operation
    const deletedLength = oldText.length - newText.length
    return {
      type: 'delete',
      position,
      length: deletedLength
    }
  } else {
    // Replace operation (delete + insert)
    let endPos = oldText.length
    let j = oldText.length - 1
    let k = newText.length - 1
    
    // Find the end of differences
    while (j >= position && k >= position && oldText[j] === newText[k]) {
      j--
      k--
    }
    
    const deletedLength = j - position + 1
    const insertedText = newText.slice(position, k + 1)
    
    return {
      type: 'replace',
      position,
      deleteLength: deletedLength,
      content: insertedText
    }
  }
}

const applyOperation = (operation: any) => {
  if (!editorElement.value) return

  const currentText = extractTextContent(editorElement.value)
  let newText = currentText

  switch (operation.type) {
    case 'insert':
      newText = currentText.slice(0, operation.position) + 
                operation.content + 
                currentText.slice(operation.position)
      break
    case 'delete':
      newText = currentText.slice(0, operation.position) + 
                currentText.slice(operation.position + operation.length)
      break
    case 'replace':
      newText = currentText.slice(0, operation.position) + 
                operation.content + 
                currentText.slice(operation.position + operation.deleteLength)
      break
  }

  // Update content and DOM
  content.value = newText
  editorElement.value.innerHTML = formatContentForDisplay(newText)
  
  // Emit content change
  emit('contentChange', newText)
}

const handleKeyDown = (event: KeyboardEvent) => {
  if (!props.canEdit) {
    event.preventDefault()
    return
  }

  // Handle keyboard shortcuts
  if (event.ctrlKey || event.metaKey) {
    switch (event.key) {
      case 'b':
        event.preventDefault()
        formatText('bold')
        break
      case 'i':
        event.preventDefault()
        formatText('italic')
        break
      case 'u':
        event.preventDefault()
        formatText('underline')
        break
      case 's':
        event.preventDefault()
        handleSave()
        break
    }
  }

  // Send cursor update after key events
  nextTick(() => {
    sendCursorPosition()
  })
}

const handleKeyUp = () => {
  sendCursorPosition()
}

const handleSelectionChange = () => {
  sendCursorPosition()
}

const handleFocus = () => {
  sendCursorPosition()
}

const handleBlur = () => {
  handleTypingStop()
}

const handlePaste = (event: ClipboardEvent) => {
  if (!props.canEdit) {
    event.preventDefault()
    return
  }

  event.preventDefault()
  const text = event.clipboardData?.getData('text/plain') || ''
  
  // Insert text at cursor position
  const selection = window.getSelection()
  if (selection && selection.rangeCount > 0) {
    const range = selection.getRangeAt(0)
    range.deleteContents()
    range.insertNode(document.createTextNode(text))
    range.collapse(false)
    selection.removeAllRanges()
    selection.addRange(range)
  }

  // Trigger input event
  const inputEvent = new Event('input', { bubbles: true })
  editorElement.value?.dispatchEvent(inputEvent)
}

const formatText = (format: string) => {
  if (!props.canEdit) return

  document.execCommand(format, false)
  sendCursorPosition()
}

const isFormatActive = (format: string): boolean => {
  return document.queryCommandState(format)
}

const insertHeading = (level: number) => {
  if (!props.canEdit) return

  document.execCommand('formatBlock', false, `h${level}`)
  sendCursorPosition()
}

const insertList = (type: 'bullet' | 'numbered') => {
  if (!props.canEdit) return

  const command = type === 'bullet' ? 'insertUnorderedList' : 'insertOrderedList'
  document.execCommand(command, false)
  sendCursorPosition()
}

const sendCursorPosition = () => {
  if (!editorElement.value || !props.canEdit) return

  const selection = window.getSelection()
  if (!selection || selection.rangeCount === 0) return

  const range = selection.getRangeAt(0)
  const position = getTextPosition(range.startContainer, range.startOffset)
  
  let selectionRange
  if (!range.collapsed) {
    const endPosition = getTextPosition(range.endContainer, range.endOffset)
    selectionRange = { start: position, end: endPosition }
  }

  sendCursorUpdate({
    position,
    selection: selectionRange
  })
}

const getTextPosition = (node: Node, offset: number): number => {
  if (!editorElement.value) return 0

  const walker = document.createTreeWalker(
    editorElement.value,
    NodeFilter.SHOW_TEXT,
    null
  )

  let position = 0
  let currentNode

  while (currentNode = walker.nextNode()) {
    if (currentNode === node) {
      return position + offset
    }
    position += currentNode.textContent?.length || 0
  }

  return position
}

const updateCollaboratorCursor = (userId: number, userName: string, cursorData: any) => {
  if (userId === currentUserId.value) return

  const color = getUserColor(userId)
  const position = cursorData.position || 0
  
  // Calculate cursor position in DOM
  const cursorElement = getCursorElementAtPosition(position)
  if (!cursorElement) return

  const rect = cursorElement.getBoundingClientRect()
  const containerRect = editorContainer.value?.getBoundingClientRect()
  
  if (!containerRect) return

  const style = {
    left: `${rect.left - containerRect.left}px`,
    top: `${rect.top - containerRect.top}px`
  }

  // Update or add cursor
  const existingIndex = collaboratorCursors.value.findIndex(c => c.userId === userId)
  const cursor: CollaboratorCursor = {
    userId,
    userName,
    position,
    selection: cursorData.selection,
    color,
    style
  }

  if (existingIndex >= 0) {
    collaboratorCursors.value[existingIndex] = cursor
  } else {
    collaboratorCursors.value.push(cursor)
  }
}

const getCursorElementAtPosition = (position: number): Element | null => {
  if (!editorElement.value) return null

  const walker = document.createTreeWalker(
    editorElement.value,
    NodeFilter.SHOW_TEXT,
    null
  )

  let currentPosition = 0
  let currentNode

  while (currentNode = walker.nextNode()) {
    const nodeLength = currentNode.textContent?.length || 0
    if (currentPosition + nodeLength >= position) {
      return currentNode.parentElement
    }
    currentPosition += nodeLength
  }

  return editorElement.value
}

const handleTypingStart = () => {
  if (!isTyping.value) {
    isTyping.value = true
    sendTypingIndicator(true)
  }

  // Reset typing timeout
  if (typingTimeout.value) {
    clearTimeout(typingTimeout.value)
  }

  typingTimeout.value = setTimeout(() => {
    handleTypingStop()
  }, 2000)
}

const handleTypingStop = () => {
  if (isTyping.value) {
    isTyping.value = false
    sendTypingIndicator(false)
  }

  if (typingTimeout.value) {
    clearTimeout(typingTimeout.value)
    typingTimeout.value = null
  }
}

const debouncedSave = () => {
  if (saveTimeout.value) {
    clearTimeout(saveTimeout.value)
  }

  saveTimeout.value = setTimeout(() => {
    handleSave()
  }, 1000)
}

const handleSave = () => {
  emit('save', content.value)
}

const formatTypingUsers = (users: string[]): string => {
  if (users.length === 1) {
    return users[0]
  } else if (users.length === 2) {
    return `${users[0]} and ${users[1]}`
  } else {
    return `${users.slice(0, -1).join(', ')} and ${users[users.length - 1]}`
  }
}

// Event handlers for collaboration service
onReceiveOperation((operation) => {
  applyOperation(operation)
})

onUserJoin((user) => {
  if (!activeUsers.value.find(u => u.id === user.id)) {
    activeUsers.value.push(user)
  }
})

onUserLeave((userId) => {
  activeUsers.value = activeUsers.value.filter(u => u.id !== userId)
  collaboratorCursors.value = collaboratorCursors.value.filter(c => c.userId !== userId)
  typingUsers.value = typingUsers.value.filter(name => {
    const user = activeUsers.value.find(u => u.id === userId)
    return user ? user.name !== name : true
  })
})

onCursorUpdate((userId, userName, cursorData) => {
  updateCollaboratorCursor(userId, userName, cursorData)
})

onTypingUpdate((userId, userName, isTyping) => {
  if (userId === currentUserId.value) return

  if (isTyping) {
    if (!typingUsers.value.includes(userName)) {
      typingUsers.value.push(userName)
    }
  } else {
    typingUsers.value = typingUsers.value.filter(name => name !== userName)
  }
})

onConnectionStatusChange((status) => {
  connectionStatus.value = status
})

// Watchers
watch(() => props.initialContent, (newContent) => {
  if (newContent !== content.value) {
    content.value = newContent
    if (editorElement.value) {
      editorElement.value.innerHTML = formatContentForDisplay(newContent)
    }
  }
})

// Lifecycle
onMounted(() => {
  initializeEditor()
})

onUnmounted(() => {
  disconnect()
  
  if (typingTimeout.value) {
    clearTimeout(typingTimeout.value)
  }
  
  if (saveTimeout.value) {
    clearTimeout(saveTimeout.value)
  }
})
</script>

<style scoped>
.editor-textarea {
  border: none;
  outline: none;
  resize: none;
  font-family: inherit;
  line-height: 1.6;
}

.editor-textarea:focus {
  outline: 2px solid hsl(var(--p));
  outline-offset: 2px;
  border-radius: 0.5rem;
}

.editor-content {
  position: relative;
  min-height: 400px;
}

.btn-active {
  background-color: hsl(var(--p));
  color: hsl(var(--pc));
}
</style>