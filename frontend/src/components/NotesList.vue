<template>
  <LoadingTransition :loading="loading" message="Loading your notes...">
    <div>

    <!-- Notes Grid -->
    <TransitionGroup
      v-if="filteredNotes.length > 0"
      name="card"
      tag="div"
      class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
      appear
    >
      <div
        v-for="note in filteredNotes"
        :key="note.id"
        class="card bg-base-100 shadow-xl hover:shadow-2xl transition-all duration-300 hover:scale-105"
      >
        <div class="card-body">
          <div class="flex justify-between items-start mb-2">
            <h2 class="card-title text-lg">{{ note.title }}</h2>
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-sm btn-circle">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"
                  />
                </svg>
              </div>
              <ul
                tabindex="0"
                class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52 z-10"
              >
                <li><a @click="$emit('open-note', note.id)">Open</a></li>
                <li v-if="note.user_role === 'owner'">
                  <a @click="$emit('manage-collaborators', note)">Manage Collaborators</a>
                </li>
                <li v-if="note.user_role === 'owner'">
                  <a @click="handleDelete(note)" class="text-error">Delete</a>
                </li>
              </ul>
            </div>
          </div>

          <div class="flex items-center gap-2 mb-3">
            <div class="badge badge-outline">{{ note.user_role }}</div>
            <div
              v-if="note.collaborators_count && note.collaborators_count > 0"
              class="badge badge-secondary"
            >
              {{ note.collaborators_count }} collaborator{{
                note.collaborators_count > 1 ? "s" : ""
              }}
            </div>
          </div>

          <p class="text-sm text-base-content/60 mb-4">
            Last updated {{ formatDate(note.updated_at) }}
          </p>

          <div class="card-actions justify-end">
            <button @click="$emit('open-note', note.id)" class="btn btn-primary btn-sm">Open</button>
          </div>
        </div>
      </div>
    </TransitionGroup>

    <!-- Empty State -->
    <div v-else class="col-span-full">
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body text-center py-12">
          <div class="text-6xl mb-4">📄</div>
          <h3 class="text-2xl font-bold mb-2">No notes found</h3>
          <p class="text-base-content/60 mb-6">
            {{ searchQuery ? 'No notes match your search criteria' : 'Create your first note to get started with collaborative editing' }}
          </p>
          <button @click="$emit('create-note')" class="btn btn-primary">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Create Note
          </button>
        </div>
      </div>
    </div>
    </div>
  </LoadingTransition>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { Note } from '@/services/api'
import LoadingTransition from './LoadingTransition.vue'

interface Props {
  notes: Note[]
  loading: boolean
  searchQuery: string
}

interface Emits {
  (e: 'open-note', noteId: number): void
  (e: 'delete-note', note: Note): void
  (e: 'manage-collaborators', note: Note): void
  (e: 'create-note'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Computed properties
const filteredNotes = computed(() => {
  if (!props.searchQuery) return props.notes
  return props.notes.filter((note) =>
    note.title.toLowerCase().includes(props.searchQuery.toLowerCase())
  )
})

// Methods
function handleDelete(note: Note) {
  if (confirm('Are you sure you want to delete this note? This action cannot be undone.')) {
    emit('delete-note', note)
  }
}

function formatDate(dateString: string) {
  const date = new Date(dateString)
  const now = new Date()
  const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60)

  if (diffInHours < 1) {
    return 'Just now'
  } else if (diffInHours < 24) {
    return `${Math.floor(diffInHours)} hour${Math.floor(diffInHours) > 1 ? 's' : ''} ago`
  } else if (diffInHours < 24 * 7) {
    const days = Math.floor(diffInHours / 24)
    return `${days} day${days > 1 ? 's' : ''} ago`
  } else {
    return date.toLocaleDateString()
  }
}
</script>