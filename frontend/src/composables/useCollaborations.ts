import { ref } from 'vue'
import { useToastStore } from '@/stores/toast'
import apiService, { type Collaboration } from '@/services/api'

export function useCollaborations() {
  const toastStore = useToastStore()
  
  // Reactive state
  const collaborations = ref<Collaboration[]>([])
  const addingCollaborator = ref(false)
  const removingCollaborator = ref<number | null>(null)

  // Load collaborations for a note
  async function loadCollaborations(noteId: number) {
    try {
      const response = await apiService.getCollaborations(noteId)
      collaborations.value = response.data.collaborations || []
    } catch (error) {
      console.error('Failed to load collaborations:', error)
      toastStore.showToast('Failed to load collaborators', 'error')
    }
  }

  // Add a new collaborator
  async function addCollaborator(
    noteId: number, 
    payload: { email: string; role: 'editor' | 'viewer' },
    onSuccess?: (collaboration: Collaboration) => void
  ) {
    try {
      addingCollaborator.value = true
      const response = await apiService.addCollaborator(noteId, {
        email: payload.email,
        role: payload.role
      })
      
      if (response.data.collaboration) {
        collaborations.value.push(response.data.collaboration)
        toastStore.showToast(response.data.message || 'Collaborator added successfully!', 'success')
        
        // Call optional success callback
        if (onSuccess) {
          onSuccess(response.data.collaboration)
        }
      }
    } catch (error: unknown) {
      console.error('Failed to add collaborator:', error)
      const errorMessage = (error as any).response?.data?.errors?.[0] || 
                          (error as any).response?.data?.error || 
                          'Failed to add collaborator'
      toastStore.showToast(errorMessage, 'error')
    } finally {
      addingCollaborator.value = false
    }
  }

  // Update collaborator role
  async function updateCollaboratorRole(
    noteId: number, 
    collaborationId: number, 
    newRole: 'editor' | 'viewer'
  ) {
    try {
      const response = await apiService.updateCollaboration(noteId, collaborationId, {
        collaboration: { role: newRole }
      })
      
      if (response.data.collaboration) {
        const index = collaborations.value.findIndex(c => c.id === collaborationId)
        if (index !== -1) {
          collaborations.value[index] = response.data.collaboration
        }
        toastStore.showToast(response.data.message || 'Role updated successfully!', 'success')
      }
    } catch (error: unknown) {
      console.error('Failed to update role:', error)
      const errorMessage = (error as any).response?.data?.errors?.[0] || 
                          (error as any).response?.data?.error || 
                          'Failed to update role'
      toastStore.showToast(errorMessage, 'error')
    }
  }

  // Remove a collaborator
  async function removeCollaborator(
    noteId: number, 
    collaborationId: number,
    onSuccess?: () => void
  ) {
    if (!confirm('Are you sure you want to remove this collaborator?')) return

    try {
      removingCollaborator.value = collaborationId
      await apiService.removeCollaborator(noteId, collaborationId)
      
      collaborations.value = collaborations.value.filter(c => c.id !== collaborationId)
      toastStore.showToast('Collaborator removed successfully!', 'success')
      
      // Call optional success callback
      if (onSuccess) {
        onSuccess()
      }
    } catch (error: unknown) {
      console.error('Failed to remove collaborator:', error)
      const errorMessage = (error as any).response?.data?.error || 'Failed to remove collaborator'
      toastStore.showToast(errorMessage, 'error')
    } finally {
      removingCollaborator.value = null
    }
  }

  return {
    // State
    collaborations,
    addingCollaborator,
    removingCollaborator,
    
    // Methods
    loadCollaborations,
    addCollaborator,
    updateCollaboratorRole,
    removeCollaborator
  }
}