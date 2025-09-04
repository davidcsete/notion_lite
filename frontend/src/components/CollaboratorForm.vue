<template>
  <form @submit.prevent="handleSubmit" :class="formClass">
    <div class="relative" :class="props.variant === 'compact' ? 'w-full' : 'flex-1'">
      <input 
        v-model="email" 
        type="email" 
        placeholder="Enter email address..." 
        :class="inputClass"
        required 
        @input="handleEmailInput"
        @focus="showDropdown = true"
        @blur="handleBlur"
        autocomplete="off"
      />
      
      <!-- Search Results Dropdown -->
      <div 
        v-if="showDropdown && (searchResults.length > 0 || searchLoading || searchQuery.length > 0)"
        class="absolute z-50 w-full mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg max-h-60 overflow-y-auto"
      >
        <!-- Loading State -->
        <div v-if="searchLoading" class="p-3 text-center">
          <span class="loading loading-spinner loading-sm mr-2"></span>
          Searching users...
        </div>
        
        <!-- Search Results -->
        <div v-else-if="searchResults.length > 0">
          <button
            v-for="user in searchResults"
            :key="user.id"
            type="button"
            class="w-full p-3 text-left hover:bg-base-200 border-b border-base-300 last:border-b-0 flex items-center gap-3"
            @mousedown.prevent="selectUser(user)"
          >
            <div class="avatar placeholder">
              <div class="bg-neutral text-neutral-content rounded-full w-8 h-8">
                <span class="text-xs">{{ user.name.charAt(0).toUpperCase() }}</span>
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <div class="font-medium truncate">{{ user.name }}</div>
              <div class="text-sm text-base-content/70 truncate">{{ user.email }}</div>
            </div>
          </button>
        </div>
        
        <!-- No Results -->
        <div v-else-if="searchQuery.length > 0" class="p-3 text-center text-base-content/70">
          No users found matching "{{ searchQuery }}"
        </div>
      </div>
    </div>
    
    <select v-model="role" :class="selectClass">
      <option value="viewer">Viewer</option>
      <option value="editor">Editor</option>
    </select>
    <button type="submit" :class="buttonClass" :disabled="loading">
      <span v-if="loading" class="loading loading-spinner loading-sm mr-2"></span>
      Add
    </button>
  </form>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { apiService, type User } from '@/services/api'

interface Props {
  loading?: boolean
  variant?: 'default' | 'compact'
}

interface Emits {
  (e: 'submit', payload: { email: string; role: 'editor' | 'viewer' }): void
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  variant: 'default'
})

const emit = defineEmits<Emits>()

// Form data
const email = ref('')
const role = ref<'editor' | 'viewer'>('viewer')

// Search functionality
const searchQuery = ref('')
const searchResults = ref<User[]>([])
const searchLoading = ref(false)
const showDropdown = ref(false)
let searchTimeout: NodeJS.Timeout | null = null

// Computed classes based on variant
const formClass = computed(() => {
  return props.variant === 'compact' 
    ? 'space-y-2' 
    : 'flex gap-2'
})

const inputClass = computed(() => {
  return props.variant === 'compact'
    ? 'input input-bordered input-sm w-full'
    : 'input input-bordered flex-1'
})

const selectClass = computed(() => {
  return props.variant === 'compact'
    ? 'select select-bordered select-sm flex-1'
    : 'select select-bordered'
})

const buttonClass = computed(() => {
  return props.variant === 'compact'
    ? 'btn btn-primary btn-sm'
    : 'btn btn-primary'
})

// Watch for search query changes with debouncing
watch(searchQuery, (newQuery) => {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  
  if (newQuery.length < 2) {
    searchResults.value = []
    return
  }
  
  searchTimeout = setTimeout(async () => {
    await performSearch(newQuery)
  }, 300)
})

// Methods
async function performSearch(query: string) {
  if (query.length < 2) return
  
  searchLoading.value = true
  try {
    const response = await apiService.searchUsers(query)
    searchResults.value = response.data.users || []
  } catch (error) {
    console.error('Error searching users:', error)
    searchResults.value = []
  } finally {
    searchLoading.value = false
  }
}

function handleEmailInput(event: Event) {
  const target = event.target as HTMLInputElement
  searchQuery.value = target.value
}

function selectUser(user: User) {
  email.value = user.email
  searchQuery.value = user.email
  searchResults.value = []
  showDropdown.value = false
}

function handleBlur() {
  // Delay hiding dropdown to allow for click events
  setTimeout(() => {
    showDropdown.value = false
  }, 200)
}

function handleSubmit() {
  emit('submit', {
    email: email.value,
    role: role.value
  })
  
  // Reset form
  email.value = ''
  role.value = 'viewer'
  searchQuery.value = ''
  searchResults.value = []
  showDropdown.value = false
}

// Expose reset method for parent components
defineExpose({
  reset: () => {
    email.value = ''
    role.value = 'viewer'
    searchQuery.value = ''
    searchResults.value = []
    showDropdown.value = false
  }
})
</script>