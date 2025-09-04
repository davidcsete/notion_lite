import axios, { type AxiosInstance, type AxiosResponse } from 'axios'

export interface User {
  id: number
  name: string
  email: string
  avatar_url?: string
}

export interface Note {
  id: number
  title: string
  content: Record<string, unknown>
  document_state?: Record<string, unknown>
  owner: User
  user_role: 'owner' | 'editor' | 'viewer'
  collaborators?: Collaboration[]
  collaborators_count?: number
  created_at: string
  updated_at: string
}

export interface Collaboration {
  id: number
  user: User
  role: 'owner' | 'editor' | 'viewer'
  created_at: string
  updated_at: string
}

export interface Operation {
  id: number
  type: 'op_insert' | 'op_delete' | 'op_retain'
  position: number
  content?: string
  user: User
  timestamp: string
  applied: boolean
}

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  user: {
    name: string
    email: string
    password: string
    password_confirmation: string
    avatar_url?: string
  }
}

export interface CreateNoteRequest {
  note: {
    title: string
    content?: Record<string, unknown>
    document_state?: Record<string, unknown>
  }
}

export interface UpdateNoteRequest {
  note: {
    title?: string
    content?: Record<string, unknown>
    document_state?: Record<string, unknown>
  }
}

export interface CreateCollaborationRequest {
  email: string
  role?: 'editor' | 'viewer'
}

export interface UpdateCollaborationRequest {
  collaboration: {
    role: 'editor' | 'viewer'
  }
}

export interface CreateOperationRequest {
  operation: {
    operation_type: 'op_insert' | 'op_delete' | 'op_retain'
    position: number
    content?: string
  }
}

export interface ApiResponse<T = unknown> {
  user?: User
  note?: Note
  notes?: Note[]
  collaboration?: Collaboration
  collaborations?: Collaboration[]
  operation?: Operation
  operations?: Operation[]
  document_state?: Record<string, unknown>
  message?: string
  error?: string
  errors?: string[]
  data?: T
}

class ApiService {
  private api: AxiosInstance

  constructor() {
    this.api = axios.create({
      baseURL: 'http://localhost:3000/api/v1',
      withCredentials: true, // Important for session cookies
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    })

    // Add response interceptor for error handling
    this.api.interceptors.response.use(
      (response) => response,
      (error) => {
        // Don't redirect on 401 for auth endpoints - let the components handle it
        if (error.response?.status === 401 && !error.config?.url?.includes('/auth/')) {
          // Only redirect if not already on login page
          if (window.location.pathname !== '/login') {
            window.location.href = '/login'
          }
        }
        return Promise.reject(error)
      }
    )
  }

  // Authentication endpoints
  async login(credentials: LoginRequest): Promise<AxiosResponse<ApiResponse>> {
    return this.api.post('/auth/login', credentials)
  }

  async logout(): Promise<AxiosResponse<ApiResponse>> {
    return this.api.delete('/auth/logout')
  }

  async getCurrentUser(): Promise<AxiosResponse<ApiResponse>> {
    return this.api.get('/auth/me')
  }

  async register(userData: RegisterRequest): Promise<AxiosResponse<ApiResponse>> {
    return this.api.post('/users', userData)
  }

  async updateProfile(userId: number, userData: Partial<User>): Promise<AxiosResponse<ApiResponse>> {
    return this.api.put(`/users/${userId}`, { user: userData })
  }

  async getUser(userId: number): Promise<AxiosResponse<ApiResponse>> {
    return this.api.get(`/users/${userId}`)
  }

  async searchUsers(query: string): Promise<AxiosResponse<ApiResponse>> {
    return this.api.get(`/users/search`, { params: { q: query } })
  }

  // Notes endpoints
  async getNotes(): Promise<AxiosResponse<ApiResponse>> {
    return this.api.get('/notes')
  }

  async getNote(noteId: number): Promise<AxiosResponse<ApiResponse>> {
    return this.api.get(`/notes/${noteId}`)
  }

  async createNote(noteData: CreateNoteRequest): Promise<AxiosResponse<ApiResponse>> {
    return this.api.post('/notes', noteData)
  }

  async updateNote(noteId: number, noteData: UpdateNoteRequest): Promise<AxiosResponse<ApiResponse>> {
    return this.api.put(`/notes/${noteId}`, noteData)
  }

  async deleteNote(noteId: number): Promise<AxiosResponse<ApiResponse>> {
    return this.api.delete(`/notes/${noteId}`)
  }

  // Collaboration endpoints
  async getCollaborations(noteId: number): Promise<AxiosResponse<ApiResponse>> {
    return this.api.get(`/notes/${noteId}/collaborations`)
  }

  async addCollaborator(noteId: number, collaborationData: CreateCollaborationRequest): Promise<AxiosResponse<ApiResponse>> {
    return this.api.post(`/notes/${noteId}/collaborations`, collaborationData)
  }

  async updateCollaboration(noteId: number, collaborationId: number, collaborationData: UpdateCollaborationRequest): Promise<AxiosResponse<ApiResponse>> {
    return this.api.put(`/notes/${noteId}/collaborations/${collaborationId}`, collaborationData)
  }

  async removeCollaborator(noteId: number, collaborationId: number): Promise<AxiosResponse<ApiResponse>> {
    return this.api.delete(`/notes/${noteId}/collaborations/${collaborationId}`)
  }

  // Operations endpoints
  async getOperations(noteId: number, since?: string): Promise<AxiosResponse<ApiResponse>> {
    const params = since ? { since } : {}
    return this.api.get(`/notes/${noteId}/operations`, { params })
  }

  async createOperation(noteId: number, operationData: CreateOperationRequest): Promise<AxiosResponse<ApiResponse>> {
    return this.api.post(`/notes/${noteId}/operations`, operationData)
  }
}

export const apiService = new ApiService()
export default apiService