<template>
  <div class="search-container">
    <Transition name="search-results" mode="out-in">
      <div v-if="hasResults" key="results" class="results-container">
        <slot name="results" />
      </div>
      <div v-else-if="isSearching" key="searching" class="searching-container">
        <div class="flex items-center justify-center py-8">
          <div class="loading loading-spinner loading-md mr-3"></div>
          <span class="text-base-content/60">Searching...</span>
        </div>
      </div>
      <div v-else key="empty" class="empty-container">
        <slot name="empty" />
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
interface Props {
  hasResults: boolean
  isSearching?: boolean
}

defineProps<Props>()
</script>

<style scoped>
.search-container {
  width: 100%;
}

.results-container,
.searching-container,
.empty-container {
  width: 100%;
}

/* Search results transition animations */
.search-results-enter-active,
.search-results-leave-active {
  transition: all 0.3s ease-in-out;
}

.search-results-enter-from {
  opacity: 0;
  transform: translateY(10px);
}

.search-results-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>