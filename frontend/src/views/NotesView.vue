<template>
  <div class="min-h-screen bg-base-200">
    <!-- Navigation -->
    <div class="navbar bg-base-100 shadow-lg">
      <div class="navbar-start">
        <router-link to="/dashboard" class="btn btn-ghost text-xl">📝 CollabNotes</router-link>
      </div>

      <div class="navbar-center">
        <div class="form-control">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search notes..."
            class="input input-bordered w-24 md:w-auto"
          />
        </div>
      </div>

      <div class="navbar-end">
        <button @click="showCreateModal = true" class="btn btn-primary mr-4">
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
          New Note
        </button>

        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
            <div class="w-10 rounded-full">
              <img
                :src="
                  authStore.user?.avatar_url ||
                  `https://ui-avatars.com/api/?name=${encodeURIComponent(
                    authStore.userName
                  )}&background=random`
                "
                :alt="authStore.userName"
              />
            </div>
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52"
          >
            <li><router-link to="/dashboard">Dashboard</router-link></li>
            <li><a>Settings</a></li>
            <li><a @click="handleLogout">Logout</a></li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="container mx-auto p-6">
      <div class="breadcrumbs text-sm mb-6">
        <ul>
          <li><router-link to="/dashboard">Dashboard</router-link></li>
          <li>Notes</li>
        </ul>
      </div>

      <!-- Notes List Component -->
      <NotesList
        :notes="notes"
        :loading="loading"
        :search-query="searchQuery"
        @open-note="openNote"
        @delete-note="handleDeleteNote"
        @manage-collaborators="showCollaborators"
        @create-note="showCreateModal = true"
      />
    </div>

    <!-- Create Note Modal -->
    <Transition name="modal" appear>
      <div v-if="showCreateModal" class="modal modal-open">
      <div class="modal-box">
        <h3 class="font-bold text-lg mb-4">Create New Note</h3>
        <form @submit.prevent="createNote">
          <div class="form-control mb-4">
            <label class="label">
              <span class="label-text">Title</span>
            </label>
            <input
              v-model="newNote.title"
              type="text"
              placeholder="Enter note title..."
              class="input input-bordered"
              required
            />
          </div>
          <div class="modal-action">
            <button type="button" @click="showCreateModal = false" class="btn">Cancel</button>
            <button type="submit" class="btn btn-primary" :disabled="creating">
              <span v-if="creating" class="loading loading-spinner loading-sm mr-2"></span>
              Create
            </button>
          </div>
        </form>
      </div>
      </div>
    </Transition>

    <!-- Collaborators Modal -->
    <Transition name="modal" appear>
      <div v-if="showCollaboratorsModal" class="modal modal-open">
      <div class="modal-box max-w-2xl">
        <h3 class="font-bold text-lg mb-4">Manage Collaborators - {{ selectedNote?.title }}</h3>

        <!-- Add Collaborator Form -->
        <div class="card bg-base-200 mb-6">
          <div class="card-body">
            <h4 class="font-semibold mb-3">Add Collaborator</h4>
            <CollaboratorForm :loading="addingCollaborator" @submit="addCollaborator" />
          </div>
        </div>

        <!-- Collaborators List -->
        <div class="space-y-3 mb-6">
          <div
            v-for="collaboration in collaborations"
            :key="collaboration.id"
            class="flex items-center justify-between p-3 bg-base-200 rounded-lg"
          >
            <div class="flex items-center gap-3">
              <div class="avatar">
                <div class="w-10 rounded-full">
                  <img
                    :src="
                      collaboration.user.avatar_url ||
                      `https://ui-avatars.com/api/?name=${encodeURIComponent(
                        collaboration.user.name
                      )}&background=random`
                    "
                    :alt="collaboration.user.name"
                  />
                </div>
              </div>
              <div>
                <div class="font-medium">{{ collaboration.user.name }}</div>
                <div class="text-sm text-base-content/60">{{ collaboration.user.email }}</div>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <select
                :value="collaboration.role"
                @change="
                  handleUpdateCollaboratorRole(
                    collaboration.id,
                    ($event.target as HTMLSelectElement).value as 'editor' | 'viewer'
                  )
                "
                class="select select-bordered select-sm"
              >
                <option value="viewer">Viewer</option>
                <option value="editor">Editor</option>
              </select>
              <button
                @click="handleRemoveCollaborator(collaboration.id)"
                class="btn btn-error btn-sm"
                :disabled="removingCollaborator === collaboration.id"
              >
                <span
                  v-if="removingCollaborator === collaboration.id"
                  class="loading loading-spinner loading-sm"
                ></span>
                <span v-else>Remove</span>
              </button>
            </div>
          </div>
        </div>

        <div class="modal-action">
          <button @click="closeCollaboratorsModal" class="btn">Close</button>
        </div>
      </div>
      </div>
    </Transition>

    <!-- Toast Component -->
    <Toast />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from "vue";
import { useRouter } from "vue-router";
import { useAuthStore } from "@/stores/auth";
import { useToastStore } from "@/stores/toast";
import { useViewTransitions } from "@/composables/useViewTransitions";
import apiService, { type Note } from "@/services/api";
import Toast from "@/components/Toast.vue";
import CollaboratorForm from "@/components/CollaboratorForm.vue";
import NotesList from "@/components/NotesList.vue";
import { useCollaborations } from "@/composables/useCollaborations";

const router = useRouter();
const authStore = useAuthStore();
const toastStore = useToastStore();
const { navigateWithTransition } = useViewTransitions(router);

// Use collaborations composable
const {
  collaborations,
  addingCollaborator,
  removingCollaborator,
  loadCollaborations,
  addCollaborator: addCollaboratorToNote,
  updateCollaboratorRole,
  removeCollaborator,
} = useCollaborations();

// Reactive state
const notes = ref<Note[]>([]);
const loading = ref(true);
const searchQuery = ref("");
const showCreateModal = ref(false);
const showCollaboratorsModal = ref(false);
const creating = ref(false);

// Selected note for collaboration management
const selectedNote = ref<Note | null>(null);

// Form data
const newNote = ref({
  title: "",
});

// Remove filteredNotes computed since it's now handled in NotesList component

// Methods
async function loadNotes() {
  try {
    loading.value = true;
    const response = await apiService.getNotes();
    notes.value = response.data.notes || [];
  } catch (error) {
    console.error("Failed to load notes:", error);
    toastStore.showToast("Failed to load notes", "error");
  } finally {
    loading.value = false;
  }
}

async function createNote() {
  try {
    creating.value = true;
    const response = await apiService.createNote({
      note: {
        title: newNote.value.title,
        content: { type: "doc", content: [] },
        document_state: { version: 1, operations: [] },
      },
    });

    if (response.data.note) {
      notes.value.unshift(response.data.note);
      toastStore.showToast(response.data.message || "Note created successfully!", "success");
      showCreateModal.value = false;
      newNote.value.title = "";

      // Navigate to the new note
      router.push(`/notes/${response.data.note.id}`);
    }
  } catch (error: any) {
    console.error("Failed to create note:", error);
    const errorMessage =
      error.response?.data?.errors?.[0] || error.response?.data?.error || "Failed to create note";
    toastStore.showToast(errorMessage, "error");
  } finally {
    creating.value = false;
  }
}

async function handleDeleteNote(note: Note) {
  try {
    await apiService.deleteNote(note.id);
    notes.value = notes.value.filter((n) => n.id !== note.id);
    toastStore.showToast("Note deleted successfully!", "success");
  } catch (error: unknown) {
    console.error("Failed to delete note:", error);
    const errorMessage = error.response?.data?.error || "Failed to delete note";
    toastStore.showToast(errorMessage, "error");
  }
}

function openNote(noteId: number) {
  navigateWithTransition(`/notes/${noteId}`, {
    name: 'editor',
    direction: 'forward',
    type: 'scale'
  });
}

async function showCollaborators(note: Note) {
  selectedNote.value = note;
  showCollaboratorsModal.value = true;
  await loadCollaborations(note.id);
}

async function addCollaborator(payload: { email: string; role: "editor" | "viewer" }) {
  if (!selectedNote.value) return;

  await addCollaboratorToNote(selectedNote.value.id, payload, () => {
    // Update the note's collaborator count on success
    const noteIndex = notes.value.findIndex((n) => n.id === selectedNote.value!.id);
    if (noteIndex !== -1) {
      notes.value[noteIndex].collaborators_count =
        (notes.value[noteIndex].collaborators_count || 0) + 1;
    }
  });
}

// Wrapper functions to handle note-specific logic
async function handleUpdateCollaboratorRole(collaborationId: number, newRole: "editor" | "viewer") {
  if (!selectedNote.value) return;
  await updateCollaboratorRole(selectedNote.value.id, collaborationId, newRole);
}

async function handleRemoveCollaborator(collaborationId: number) {
  if (!selectedNote.value) return;

  await removeCollaborator(selectedNote.value.id, collaborationId, () => {
    // Update the note's collaborator count on success
    const noteIndex = notes.value.findIndex((n) => n.id === selectedNote.value!.id);
    if (noteIndex !== -1) {
      notes.value[noteIndex].collaborators_count = Math.max(
        (notes.value[noteIndex].collaborators_count || 1) - 1,
        0
      );
    }
  });
}

function closeCollaboratorsModal() {
  showCollaboratorsModal.value = false;
  selectedNote.value = null;
  collaborations.value = [];
}

// formatDate function moved to NotesList component

async function handleLogout() {
  const result = await authStore.logout();
  if (result.success) {
    router.push("/login");
  }
}

// Lifecycle
onMounted(() => {
  loadNotes();
});
</script>
