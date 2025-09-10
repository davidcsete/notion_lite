<template>
  <Transition
    name="loading"
    mode="out-in"
    appear
  >
    <div v-if="loading" class="loading-container">
      <div class="loading-content">
        <div class="loading loading-spinner loading-lg text-primary"></div>
        <p v-if="message" class="mt-4 text-base-content/60">{{ message }}</p>
      </div>
    </div>
    <div v-else class="content-container">
      <slot />
    </div>
  </Transition>
</template>

<script setup lang="ts">
interface Props {
  loading: boolean
  message?: string
}

defineProps<Props>()
</script>

<style scoped>
.loading-container {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 200px;
  width: 100%;
}

.loading-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.content-container {
  width: 100%;
}

/* Loading transition animations */
.loading-enter-active,
.loading-leave-active {
  transition: all 0.3s ease-in-out;
}

.loading-enter-from {
  opacity: 0;
  transform: scale(0.9);
}

.loading-leave-to {
  opacity: 0;
  transform: scale(1.1);
}
</style>