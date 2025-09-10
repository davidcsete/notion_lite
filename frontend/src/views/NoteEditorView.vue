<template>
  <div class="min-h-screen bg-base-200">
    <!-- Navigation -->
    <div class="navbar bg-base-100 shadow-lg">
      <div class="navbar-start">
        <router-link to="/notes" class="btn btn-ghost">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Notes
        </router-link>
      </div>
      
      <div class="navbar-center">
        <input 
          v-model="note.title"
          @blur="saveNote"
          type="text" 
          placeholder="Untitled Note" 
          class="input input-ghost text-xl font-bold text-center max-w-md"
          :disabled="!canEdit"
        />
      </div>
      
      <div class="navbar-end">
        <div class="flex items-center space-x-2 mr-4">
          <div :class="['badge', saveStatus === 'saved' ? 'badge-success' : saveStatus === 'saving' ? 'badge-warning' : 'badge-error']">
            <span v-if="saveStatus === 'saving'" class="loading loading-spinner loading-xs mr-1"></span>
            {{ saveStatus === 'saved' ? 'Saved' : saveStatus === 'saving' ? 'Saving...' : 'Error' }}
          </div>
          <div class="badge badge-outline">{{ note.user_role }}</div>
          <div v-if="collaborations.length > 0" class="badge badge-secondary">
            {{ collaborations.length }} collaborator{{ collaborations.length > 1 ? 's' : '' }}
          </div>
        </div>
        
        <button 
          v-if="note.user_role === 'owner'" 
          @click="showCollaboratorsPanel = !showCollaboratorsPanel" 
          class="btn btn-outline btn-sm mr-2"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
          </svg>
          Share
        </button>
        
        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
            <div class="w-10 rounded-full">
              <img 
                :src="authStore.user?.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(authStore.userName)}&background=random`" 
                :alt="authStore.userName"
              />
            </div>
          </div>
          <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
            <li><router-link to="/dashboard">Dashboard</router-link></li>
            <li><router-link to="/notes">All Notes</router-link></li>
            <li><a>Settings</a></li>
            <li><a @click="handleLogout">Logout</a></li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex justify-center items-center py-12">
      <span class="loading loading-spinner loading-lg"></span>
    </div>

    <!-- Editor Content -->
    <div v-else class="container mx-auto p-6">
      <div class="card bg-base-100 shadow-xl min-h-[600px]">
        <div class="card-body">
          <!-- Toolbar -->
          <div v-if="canEdit" class="flex flex-wrap gap-2 mb-4 pb-4 border-b border-base-300">
            <div class="btn-group">
              <button class="btn btn-sm btn-outline" title="Heading">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 2l3 6 3-6M6 18l3-6 3 6M6 10h12" />
                </svg>
              </button>
              <button class="btn btn-sm btn-outline" title="Code">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                </svg>
              </button>
              <button class="btn btn-sm btn-outline" title="List">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7" />
                </svg>
              </button>
            </div>
            
            <div class="divider divider-horizontal"></div>
            
            <div class="btn-group">
              <button class="btn btn-sm btn-outline" title="Bold">B</button>
              <button class="btn btn-sm btn-outline" title="Italic">I</button>
              <button class="btn btn-sm btn-outline" title="Underline">U</button>
            </div>
          </div>
          
          <!-- Read-only notice for viewers -->
          <div v-if="!canEdit" class="alert alert-info mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <span>You have view-only access to this note.</span>
          </div>
          
          <!-- Editor Area -->
          <div class="flex-1">
            <NoteEditor
              :note-id="note.id"
              :initial-content="noteContent"
              :can-edit="canEdit"
              @content-change="handleContentChange"
              @save="handleSave"
            />
          </div>
          
          <!-- Status Bar -->
          <div class="flex justify-between items-center pt-4 border-t border-base-300 text-sm opacity-60">
            <div>
              Last saved: {{ formatDate(note.updated_at) }}
            </div>
            <div>
              {{ wordCount }} words • {{ characterCount }} characters
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Collaborators Panel (Sidebar) -->
    <div v-if="showCollaboratorsPanel" class="fixed right-4 top-1/2 transform -translate-y-1/2 z-50">
      <div class="card bg-base-100 shadow-xl w-80">
        <div class="card-body p-4">
          <div class="flex justify-between items-center mb-3">
            <h3 class="font-bold text-sm">Collaborators</h3>
            <button @click="showCollaboratorsPanel = false" class="btn btn-ghost btn-xs">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          
          <!-- Add Collaborator Form -->
          <div class="mb-4">
            <CollaboratorForm 
              variant="compact"
              :loading="addingCollaborator"
              @submit="addCollaborator"
            />
          </div>

          <!-- Collaborators List -->
          <div class="space-y-2 max-h-64 overflow-y-auto">
            <div v-for="collaboration in collaborations" :key="collaboration.id" class="flex items-center justify-between p-2 bg-base-200 rounded">
              <div class="flex items-center gap-2">
                <div class="avatar">
                  <div class="w-6 rounded-full">
                    <img 
                      :src="collaboration.user.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(collaboration.user.name)}&background=random`" 
                      :alt="collaboration.user.name"
                    />
                  </div>
                </div>
                <div>
                  <div class="text-xs font-medium">{{ collaboration.user.name }}</div>
                  <div class="text-xs opacity-60">{{ collaboration.user.email }}</div>
                </div>
              </div>
              <div class="flex items-center gap-1">
                <select 
                  :value="collaboration.role" 
                  @change="handleUpdateCollaboratorRole(collaboration.id, ($event.target as HTMLSelectElement).value as 'editor' | 'viewer')"
                  class="select select-bordered select-xs"
                >
                  <option value="viewer">Viewer</option>
                  <option value="editor">Editor</option>
                </select>
                <button 
                  @click="handleRemoveCollaborator(collaboration.id)" 
                  class="btn btn-error btn-xs"
                  :disabled="removingCollaborator === collaboration.id"
                >
                  <span v-if="removingCollaborator === collaboration.id" class="loading loading-spinner loading-xs"></span>
                  <span v-else>×</span>
                </button>
              </div>
            </div>
            
            <!-- Empty State -->
            <div v-if="collaborations.length === 0" class="text-center py-4">
              <div class="text-2xl mb-2">👥</div>
              <p class="text-xs opacity-60">No collaborators yet</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Toast Component -->
    <Toast />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import apiService, { type Note } from '@/services/api'
import Toast from '@/components/Toast.vue'
import CollaboratorForm from '@/components/CollaboratorForm.vue'
import NoteEditor from '@/components/NoteEditor.vue'
import { useCollaborations } from '@/composables/useCollaborations'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const toastStore = useToastStore()

// Use collaborations composable
const {
  collaborations,
  addingCollaborator,
  removingCollaborator,
  loadCollaborations,
  addCollaborator: addCollaboratorToNote,
  updateCollaboratorRole,
  removeCollaborator
} = useCollaborations()

// Reactive state
const note = ref<Note>({
  id: 0,
  title: '',
  content: {},
  owner: { id: 0, name: '', email: '' },
  user_role: 'viewer',
  created_at: '',
  updated_at: ''
})

const loading = ref(true)
const saveStatus = ref<'saved' | 'saving' | 'error'>('saved')
const showCollaboratorsPanel = ref(false)

// Content management
const noteContent = ref('')
const saveTimeout = ref<number | null>(null)



// Computed properties
const canEdit = computed(() => {
  return note.value.user_role === 'owner' || note.value.user_role === 'editor'
})

const wordCount = computed(() => {
  return noteContent.value.trim().split(/\s+/).filter(word => word.length > 0).length
})

const characterCount = computed(() => {
  return noteContent.value.length
})

// Methods
async function loadNote() {
  try {
    loading.value = true
    const noteId = parseInt(route.params.id as string)
    
    if (isNaN(noteId)) {
      toastStore.showToast('Invalid note ID', 'error')
      router.push('/notes')
      return
    }

    const response = await apiService.getNote(noteId)
    if (response.data.note) {
      note.value = response.data.note
      noteContent.value = extractTextContent(note.value.content)
      
      // Load collaborations if user is owner
      if (note.value.user_role === 'owner') {
        await loadCollaborations(note.value.id)
      }
    }
  } catch (error: unknown) {
    console.error('Failed to load note:', error)
    if (error.response?.status === 404) {
      toastStore.showToast('Note not found', 'error')
      router.push('/notes')
    } else if (error.response?.status === 403) {
      toastStore.showToast('You do not have access to this note', 'error')
      router.push('/notes')
    } else {
      toastStore.showToast('Failed to load note', 'error')
    }
  } finally {
    loading.value = false
  }
}



function extractTextContent(content: Record<string, unknown>): string {
  // Simple text extraction - in a real app, this would handle rich text properly
  if (content && typeof content === 'object' && 'text' in content) {
    return content.text as string
  }
  return ''
}

function handleContentChange(newContent: string) {
  if (!canEdit.value) return
  
  noteContent.value = newContent
  
  // Clear existing timeout
  if (saveTimeout.value) {
    clearTimeout(saveTimeout.value)
  }
  
  // Set saving status
  saveStatus.value = 'saving'
  
  // Debounce save operation
  saveTimeout.value = setTimeout(() => {
    saveNote()
  }, 1000)
}

function handleSave(content: string) {
  noteContent.value = content
  saveNote()
}

async function saveNote() {
  if (!canEdit.value) return
  
  try {
    saveStatus.value = 'saving'
    
    const response = await apiService.updateNote(note.value.id, {
      note: {
        title: note.value.title,
        content: { text: noteContent.value },
        document_state: note.value.document_state
      }
    })
    
    if (response.data.note) {
      note.value.updated_at = response.data.note.updated_at
      saveStatus.value = 'saved'
    }
  } catch (error: unknown) {
    console.error('Failed to save note:', error)
    saveStatus.value = 'error'
    const errorMessage = error.response?.data?.error || 'Failed to save note'
    toastStore.showToast(errorMessage, 'error')
  }
}

async function addCollaborator(payload: { email: string; role: 'editor' | 'viewer' }) {
  await addCollaboratorToNote(note.value.id, payload)
}

async function handleUpdateCollaboratorRole(collaborationId: number, newRole: 'editor' | 'viewer') {
  await updateCollaboratorRole(note.value.id, collaborationId, newRole)
}

async function handleRemoveCollaborator(collaborationId: number) {
  await removeCollaborator(note.value.id, collaborationId)
}

function formatDate(dateString: string) {
  if (!dateString) return 'Never'
  
  const date = new Date(dateString)
  const now = new Date()
  const diffInMinutes = (now.getTime() - date.getTime()) / (1000 * 60)
  
  if (diffInMinutes < 1) {
    return 'Just now'
  } else if (diffInMinutes < 60) {
    return `${Math.floor(diffInMinutes)} minute${Math.floor(diffInMinutes) > 1 ? 's' : ''} ago`
  } else if (diffInMinutes < 60 * 24) {
    const hours = Math.floor(diffInMinutes / 60)
    return `${hours} hour${hours > 1 ? 's' : ''} ago`
  } else {
    return date.toLocaleDateString()
  }
}

async function handleLogout() {
  const result = await authStore.logout()
  if (result.success) {
    router.push('/login')
  }
}

// Watchers
watch(() => route.params.id, (newId) => {
  if (newId) {
    loadNote()
  }
})

// Lifecycle
onMounted(() => {
  loadNote()
})

// Cleanup
onMounted(() => {
  return () => {
    if (saveTimeout.value) {
      clearTimeout(saveTimeout.value)
    }
  }
})
</script>