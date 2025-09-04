class Api::V1::NotesController < Api::V1::BaseController
  before_action :set_note, only: [:show, :update, :destroy]
  before_action :require_access, only: [:show]
  before_action :require_edit_access, only: [:update, :destroy]
  
  def index
    @notes = current_user.accessible_notes.includes(:owner, :collaborators)
    render_success({ notes: @notes.map { |note| note_json(note) } })
  end
  
  def show
    render_success({ note: detailed_note_json(@note) })
  end
  
  def create
    @note = current_user.owned_notes.build(note_params)
    
    if @note.save
      render_success({ note: detailed_note_json(@note) }, 'Note created successfully!')
    else
      render_errors(@note.errors.full_messages)
    end
  end
  
  def update
    if @note.update(note_params)
      render_success({ note: detailed_note_json(@note) }, 'Note updated successfully!')
    else
      render_errors(@note.errors.full_messages)
    end
  end
  
  def destroy
    if @note.owner == current_user
      @note.destroy
      render_success({}, 'Note deleted successfully!')
    else
      render_error('Only the owner can delete this note', :forbidden)
    end
  end
  
  private
  
  def set_note
    @note = Note.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error('Note not found', :not_found)
  end
  
  def require_access
    unless @note.accessible_by?(current_user)
      render_error('Access denied', :forbidden)
    end
  end
  
  def require_edit_access
    user_role = @note.user_role(current_user)
    unless user_role == 'owner' || user_role == 'editor'
      render_error('Edit permission required', :forbidden)
    end
  end
  
  def note_params
    params.require(:note).permit(:title, content: {}, document_state: {})
  end
  
  def note_json(note)
    {
      id: note.id,
      title: note.title,
      owner: {
        id: note.owner.id,
        name: note.owner.name,
        avatar_url: note.owner.avatar_url
      },
      user_role: note.user_role(current_user),
      collaborators_count: note.collaborators.count,
      updated_at: note.updated_at.iso8601,
      created_at: note.created_at.iso8601
    }
  end
  
  def detailed_note_json(note)
    {
      id: note.id,
      title: note.title,
      content: note.content,
      document_state: note.document_state,
      owner: {
        id: note.owner.id,
        name: note.owner.name,
        email: note.owner.email,
        avatar_url: note.owner.avatar_url
      },
      user_role: note.user_role(current_user),
      collaborators: note.collaborators.map do |user|
        collaboration = note.collaborations.find_by(user: user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          avatar_url: user.avatar_url,
          role: collaboration.role
        }
      end,
      updated_at: note.updated_at.iso8601,
      created_at: note.created_at.iso8601
    }
  end
end