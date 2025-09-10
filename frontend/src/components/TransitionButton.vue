<template>
  <button
    :class="buttonClasses"
    :disabled="disabled || loading"
    @click="handleClick"
    v-bind="$attrs"
  >
    <Transition name="button-content" mode="out-in">
      <div v-if="loading" key="loading" class="flex items-center">
        <span class="loading loading-spinner loading-sm mr-2"></span>
        {{ loadingText || 'Loading...' }}
      </div>
      <div v-else key="content" class="flex items-center">
        <slot name="icon" />
        <span v-if="$slots.default"><slot /></span>
      </div>
    </Transition>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'secondary' | 'accent' | 'ghost' | 'outline' | 'error'
  size?: 'xs' | 'sm' | 'md' | 'lg'
  loading?: boolean
  loadingText?: string
  disabled?: boolean
  block?: boolean
}

interface Emits {
  (e: 'click', event: MouseEvent): void
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  loading: false,
  disabled: false,
  block: false
})

const emit = defineEmits<Emits>()

const buttonClasses = computed(() => {
  const classes = ['btn', 'transition-all', 'duration-200', 'hover:scale-105', 'active:scale-95']
  
  // Variant classes
  switch (props.variant) {
    case 'primary':
      classes.push('btn-primary')
      break
    case 'secondary':
      classes.push('btn-secondary')
      break
    case 'accent':
      classes.push('btn-accent')
      break
    case 'ghost':
      classes.push('btn-ghost')
      break
    case 'outline':
      classes.push('btn-outline')
      break
    case 'error':
      classes.push('btn-error')
      break
  }
  
  // Size classes
  switch (props.size) {
    case 'xs':
      classes.push('btn-xs')
      break
    case 'sm':
      classes.push('btn-sm')
      break
    case 'lg':
      classes.push('btn-lg')
      break
  }
  
  if (props.block) {
    classes.push('btn-block')
  }
  
  if (props.loading || props.disabled) {
    classes.push('btn-disabled')
  }
  
  return classes.join(' ')
})

const handleClick = (event: MouseEvent) => {
  if (!props.loading && !props.disabled) {
    emit('click', event)
  }
}
</script>

<style scoped>
/* Button content transition */
.button-content-enter-active,
.button-content-leave-active {
  transition: all 0.2s ease-in-out;
}

.button-content-enter-from,
.button-content-leave-to {
  opacity: 0;
  transform: scale(0.9);
}
</style>