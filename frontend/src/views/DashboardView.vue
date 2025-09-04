<template>
  <div class="min-h-screen bg-base-200">
    <!-- Navigation -->
    <div class="navbar bg-base-100 shadow-lg">
      <div class="navbar-start">
        <div class="dropdown">
          <div tabindex="0" role="button" class="btn btn-ghost lg:hidden">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h8m-8 6h16" />
            </svg>
          </div>
          <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52">
            <li><router-link to="/notes">Notes</router-link></li>
            <li><a>Shared with me</a></li>
            <li><a>Recent</a></li>
          </ul>
        </div>
        <a class="btn btn-ghost text-xl">📝 CollabNotes</a>
      </div>
      
      <div class="navbar-center hidden lg:flex">
        <ul class="menu menu-horizontal px-1">
          <li><router-link to="/notes" class="btn btn-ghost">Notes</router-link></li>
          <li><a class="btn btn-ghost">Shared with me</a></li>
          <li><a class="btn btn-ghost">Recent</a></li>
        </ul>
      </div>
      
      <div class="navbar-end">
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
            <li>
              <a class="justify-between">
                Profile
                <span class="badge">New</span>
              </a>
            </li>
            <li><a>Settings</a></li>
            <li><a @click="handleLogout">Logout</a></li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="container mx-auto p-6">
      <!-- Welcome Section -->
      <div class="hero bg-gradient-to-r from-primary to-secondary text-primary-content rounded-lg mb-8">
        <div class="hero-content text-center">
          <div class="max-w-md">
            <h1 class="mb-5 text-5xl font-bold">Welcome back, {{ authStore.userName }}!</h1>
            <p class="mb-5">
              Ready to collaborate? Create a new note or continue working on your existing documents.
            </p>
            <button @click="createNote" class="btn btn-accent">Create New Note</button>
          </div>
        </div>
      </div>

      <!-- Stats -->
      <div class="stats shadow mb-8 w-full">
        <div class="stat">
          <div class="stat-figure text-primary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
          </div>
          <div class="stat-title">Total Notes</div>
          <div class="stat-value text-primary">{{ ownedNotesCount }}</div>
          <div class="stat-desc">Created by you</div>
        </div>
        
        <div class="stat">
          <div class="stat-figure text-secondary">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
          </div>
          <div class="stat-title">Shared Notes</div>
          <div class="stat-value text-secondary">{{ sharedNotesCount }}</div>
          <div class="stat-desc">Collaborating with others</div>
        </div>
        
        <div class="stat">
          <div class="stat-figure text-accent">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
            </svg>
          </div>
          <div class="stat-title">Recent Activity</div>
          <div class="stat-value text-accent">{{ recentNotesCount }}</div>
          <div class="stat-desc">Updated this week</div>
        </div>
      </div>

      <!-- Recent Notes Section -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="flex justify-between items-center mb-4">
            <h2 class="card-title">Recent Notes</h2>
            <router-link to="/notes" class="btn btn-outline btn-sm">View All</router-link>
          </div>
          
          <!-- Loading State -->
          <div v-if="loading" class="flex justify-center items-center py-12">
            <span class="loading loading-spinner loading-lg"></span>
          </div>
          
          <!-- Notes List -->
          <div v-else-if="recentNotes.length > 0" class="space-y-3">
            <div v-for="note in recentNotes" :key="note.id" class="flex items-center justify-between p-4 bg-base-200 rounded-lg hover:bg-base-300 transition-colors">
              <div class="flex items-center gap-3">
                <div class="text-2xl">📝</div>
                <div>
                  <h3 class="font-medium">{{ note.title }}</h3>
                  <div class="flex items-center gap-2 text-sm text-base-content/60">
                    <span class="badge badge-outline badge-xs">{{ note.user_role }}</span>
                    <span>Updated {{ formatDate(note.updated_at) }}</span>
                    <span v-if="note.collaborators_count && note.collaborators_count > 0">
                      • {{ note.collaborators_count }} collaborator{{ note.collaborators_count > 1 ? 's' : '' }}
                    </span>
                  </div>
                </div>
              </div>
              <button @click="openNote(note.id)" class="btn btn-primary btn-sm">
                Open
              </button>
            </div>
          </div>
          
          <!-- Empty State -->
          <div v-else class="text-center py-12">
            <div class="text-6xl mb-4">📝</div>
            <h3 class="text-2xl font-bold mb-2">No notes yet</h3>
            <p class="text-base-content/60 mb-6">
              Create your first note to start collaborating with your team
            </p>
            <button @click="createNote" class="btn btn-primary">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Create Your First Note
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useToastStore } from '@/stores/toast'
import apiService, { type Note } from '@/services/api'

const router = useRouter()
const authStore = useAuthStore()
const toastStore = useToastStore()

// Reactive state
const notes = ref<Note[]>([])
const loading = ref(true)

// Computed properties
const recentNotes = computed(() => {
  return notes.value
    .sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())
    .slice(0, 5)
})

const ownedNotesCount = computed(() => {
  return notes.value.filter(note => note.user_role === 'owner').length
})

const sharedNotesCount = computed(() => {
  return notes.value.filter(note => note.user_role !== 'owner').length
})

const recentNotesCount = computed(() => {
  const oneWeekAgo = new Date()
  oneWeekAgo.setDate(oneWeekAgo.getDate() - 7)
  
  return notes.value.filter(note => 
    new Date(note.updated_at) > oneWeekAgo
  ).length
})

// Methods
async function loadNotes() {
  try {
    loading.value = true
    const response = await apiService.getNotes()
    notes.value = response.data.notes || []
  } catch (error) {
    console.error('Failed to load notes:', error)
    toastStore.showToast('Failed to load notes', 'error')
  } finally {
    loading.value = false
  }
}

async function createNote() {
  try {
    const response = await apiService.createNote({
      note: {
        title: 'Untitled Note',
        content: { type: 'doc', content: [] },
        document_state: { version: 1, operations: [] }
      }
    })
    
    if (response.data.note) {
      toastStore.showToast(response.data.message || 'Note created successfully!', 'success')
      router.push(`/notes/${response.data.note.id}`)
    }
  } catch (error: unknown) {
    console.error('Failed to create note:', error)
    const errorMessage = error.response?.data?.errors?.[0] || error.response?.data?.error || 'Failed to create note'
    toastStore.showToast(errorMessage, 'error')
  }
}

function openNote(noteId: number) {
  router.push(`/notes/${noteId}`)
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  const now = new Date()
  const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60)
  
  if (diffInHours < 1) {
    return 'just now'
  } else if (diffInHours < 24) {
    return `${Math.floor(diffInHours)} hour${Math.floor(diffInHours) > 1 ? 's' : ''} ago`
  } else if (diffInHours < 24 * 7) {
    const days = Math.floor(diffInHours / 24)
    return `${days} day${days > 1 ? 's' : ''} ago`
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

// Lifecycle
onMounted(async () => {
  // Fetch current user if not already loaded
  if (!authStore.isAuthenticated) {
    const result = await authStore.fetchCurrentUser()
    if (!result.success) {
      router.push('/login')
      return
    }
  }
  
  // Load notes
  await loadNotes()
})
</script>