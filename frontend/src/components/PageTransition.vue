<template>
  <Transition
    :name="transitionName"
    :mode="mode"
    :appear="appear"
    @before-enter="onBeforeEnter"
    @enter="onEnter"
    @after-enter="onAfterEnter"
    @before-leave="onBeforeLeave"
    @leave="onLeave"
    @after-leave="onAfterLeave"
  >
    <slot />
  </Transition>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'

interface Props {
  name?: string
  mode?: 'in-out' | 'out-in' | 'default'
  appear?: boolean
  direction?: 'forward' | 'back'
}

interface Emits {
  (e: 'before-enter', el: Element): void
  (e: 'enter', el: Element, done: () => void): void
  (e: 'after-enter', el: Element): void
  (e: 'before-leave', el: Element): void
  (e: 'leave', el: Element, done: () => void): void
  (e: 'after-leave', el: Element): void
}

const props = withDefaults(defineProps<Props>(), {
  name: 'page',
  mode: 'out-in',
  appear: true,
  direction: 'forward'
})

const emit = defineEmits<Emits>()

const route = useRoute()
const isTransitioning = ref(false)

// Compute transition name based on route and direction
const transitionName = computed(() => {
  if (props.name !== 'page') return props.name
  
  // Use different transitions based on direction
  if (props.direction === 'back') {
    return 'page-back'
  }
  
  // Special transitions for specific routes
  const routeName = route.name as string
  if (routeName?.includes('auth')) {
    return 'fade'
  }
  
  if (routeName === 'note-editor') {
    return 'modal'
  }
  
  return 'page'
})

// Transition event handlers
const onBeforeEnter = (el: Element) => {
  isTransitioning.value = true
  emit('before-enter', el)
}

const onEnter = (el: Element, done: () => void) => {
  emit('enter', el, done)
}

const onAfterEnter = (el: Element) => {
  isTransitioning.value = false
  emit('after-enter', el)
}

const onBeforeLeave = (el: Element) => {
  emit('before-leave', el)
}

const onLeave = (el: Element, done: () => void) => {
  emit('leave', el, done)
}

const onAfterLeave = (el: Element) => {
  emit('after-leave', el)
}

// Expose reactive state
defineExpose({
  isTransitioning
})
</script>