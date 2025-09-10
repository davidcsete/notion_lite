<template>
  <div class="demo-container p-6 bg-base-100 rounded-lg shadow-lg">
    <h2 class="text-2xl font-bold mb-6">View Transitions Demo</h2>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Navigation Transitions -->
      <div class="card bg-base-200 p-4">
        <h3 class="font-semibold mb-4">Navigation Transitions</h3>
        <div class="space-y-2">
          <TransitionButton
            @click="navigateWithTransition('/dashboard', { name: 'dashboard' })"
            variant="primary"
            size="sm"
            class="w-full"
          >
            Dashboard (Fade Up)
          </TransitionButton>
          
          <TransitionButton
            @click="navigateWithTransition('/notes', { name: 'notes' })"
            variant="secondary"
            size="sm"
            class="w-full"
          >
            Notes (Slide)
          </TransitionButton>
          
          <TransitionButton
            @click="navigateWithTransition('/notes/1', { name: 'editor' })"
            variant="accent"
            size="sm"
            class="w-full"
          >
            Note Editor (Scale)
          </TransitionButton>
        </div>
      </div>

      <!-- Element Transitions -->
      <div class="card bg-base-200 p-4">
        <h3 class="font-semibold mb-4">Element Transitions</h3>
        <div class="space-y-4">
          <TransitionButton
            @click="toggleCards"
            variant="outline"
            size="sm"
            class="w-full"
          >
            Toggle Cards
          </TransitionButton>
          
          <TransitionGroup
            name="card"
            tag="div"
            class="space-y-2"
          >
            <div
              v-for="card in visibleCards"
              :key="card.id"
              class="card bg-primary text-primary-content p-3"
            >
              <div class="font-medium">{{ card.title }}</div>
              <div class="text-sm opacity-80">{{ card.description }}</div>
            </div>
          </TransitionGroup>
        </div>
      </div>

      <!-- Loading Transitions -->
      <div class="card bg-base-200 p-4">
        <h3 class="font-semibold mb-4">Loading Transitions</h3>
        <div class="space-y-4">
          <TransitionButton
            @click="simulateLoading"
            :loading="isLoading"
            loading-text="Loading..."
            variant="primary"
            size="sm"
            class="w-full"
          >
            Simulate Loading
          </TransitionButton>
          
          <LoadingTransition :loading="isLoading" message="Fetching data...">
            <div class="bg-success text-success-content p-3 rounded">
              <div class="font-medium">Data Loaded!</div>
              <div class="text-sm">This content appears after loading.</div>
            </div>
          </LoadingTransition>
        </div>
      </div>

      <!-- Modal Transitions -->
      <div class="card bg-base-200 p-4">
        <h3 class="font-semibold mb-4">Modal Transitions</h3>
        <TransitionButton
          @click="showModal = true"
          variant="ghost"
          size="sm"
          class="w-full"
        >
          Show Modal
        </TransitionButton>
        
        <Transition name="modal" appear>
          <div v-if="showModal" class="modal modal-open">
            <div class="modal-box">
              <h3 class="font-bold text-lg">Demo Modal</h3>
              <p class="py-4">This modal uses smooth transitions!</p>
              <div class="modal-action">
                <button @click="showModal = false" class="btn">Close</button>
              </div>
            </div>
          </div>
        </Transition>
      </div>
    </div>

    <!-- Browser Support Info -->
    <div class="mt-6 p-4 bg-info text-info-content rounded-lg">
      <div class="flex items-center gap-2">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
        </svg>
        <span class="font-medium">
          View Transitions API: {{ supportsViewTransitions ? 'Supported' : 'Not Supported (using Vue transitions)' }}
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useViewTransitions } from '@/composables/useViewTransitions'
import TransitionButton from './TransitionButton.vue'
import LoadingTransition from './LoadingTransition.vue'

const router = useRouter()
const { navigateWithTransition, supportsViewTransitions } = useViewTransitions(router)

const showModal = ref(false)
const isLoading = ref(false)
const visibleCards = ref([
  { id: 1, title: 'Card 1', description: 'First demo card' },
  { id: 2, title: 'Card 2', description: 'Second demo card' },
  { id: 3, title: 'Card 3', description: 'Third demo card' }
])

const allCards = [
  { id: 1, title: 'Card 1', description: 'First demo card' },
  { id: 2, title: 'Card 2', description: 'Second demo card' },
  { id: 3, title: 'Card 3', description: 'Third demo card' },
  { id: 4, title: 'Card 4', description: 'Fourth demo card' },
  { id: 5, title: 'Card 5', description: 'Fifth demo card' }
]

const toggleCards = () => {
  if (visibleCards.value.length === 3) {
    visibleCards.value = allCards
  } else {
    visibleCards.value = allCards.slice(0, 3)
  }
}

const simulateLoading = async () => {
  isLoading.value = true
  await new Promise(resolve => setTimeout(resolve, 2000))
  isLoading.value = false
}
</script>

<style scoped>
.demo-container {
  max-width: 800px;
  margin: 0 auto;
}
</style>