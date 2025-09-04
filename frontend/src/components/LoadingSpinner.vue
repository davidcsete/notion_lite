<template>
  <div class="flex items-center justify-center" :class="containerClass">
    <span class="loading loading-spinner" :class="spinnerClass"></span>
    <span v-if="text" class="ml-2" :class="textClass">{{ text }}</span>
  </div>
</template>

<script setup lang="ts">
interface Props {
  size?: 'xs' | 'sm' | 'md' | 'lg'
  text?: string
  containerClass?: string
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  containerClass: ''
})

const spinnerClass = computed(() => {
  const sizeClasses = {
    xs: 'loading-xs',
    sm: 'loading-sm', 
    md: 'loading-md',
    lg: 'loading-lg'
  }
  return sizeClasses[props.size]
})

const textClass = computed(() => {
  const sizeClasses = {
    xs: 'text-xs',
    sm: 'text-sm',
    md: 'text-base',
    lg: 'text-lg'
  }
  return sizeClasses[props.size]
})
</script>

<script lang="ts">
import { computed } from 'vue'
export default {
  name: 'LoadingSpinner'
}
</script>