class Api::V1::CollaborationsController < Api::V1::BaseController
  before_action :find_note
  before_action :require_note_access, only: [:index]
  before_action :require_owner_access, only: [:create, :update, :destroy]
  before_action :find_collaboration, only: [:update, :destroy]

  def index
    collaborations = @note.collaborations.includes(:user)
    render json: {
      collaborations: collaborations.map { |c| collaboration_json(c) }
    }
  end

  def create
    user = User.find_by(email: params[:email])
    
    unless user
      render json: { error: 'User not found' }, status: :not_found
      return
    end

    if user == @note.owner
      render json: { error: 'Cannot add owner as collaborator' }, status: :unprocessable_entity
      return
    end

    collaboration = @note.collaborations.build(
      user: user,
      role: params[:role] || 'viewer'
    )

    if collaboration.save
      render json: {
        collaboration: collaboration_json(collaboration),
        message: 'Collaborator added successfully!'
      }
    else
      render json: { errors: collaboration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    begin
      if @collaboration.update(collaboration_params)
        render json: {
          collaboration: collaboration_json(@collaboration),
          message: 'Collaboration updated successfully!'
        }
      else
        render json: { errors: @collaboration.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ArgumentError => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end
  end

  def destroy
    @collaboration.destroy
    render json: { message: 'Collaborator removed successfully!' }
  end

  private

  def find_note
    @note = Note.find(params[:note_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Note not found' }, status: :not_found
  end

  def require_note_access
    require_owner_or_collaborator(@note)
  end

  def require_owner_access
    unless @note.owner == current_user
      render json: { error: 'Only the owner can manage collaborators' }, status: :forbidden
    end
  end

  def find_collaboration
    @collaboration = @note.collaborations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Collaboration not found' }, status: :not_found
  end

  def collaboration_params
    params.require(:collaboration).permit(:role)
  end

  def collaboration_json(collaboration)
    {
      id: collaboration.id,
      user: {
        id: collaboration.user.id,
        name: collaboration.user.name,
        email: collaboration.user.email,
        avatar_url: collaboration.user.avatar_url
      },
      role: collaboration.role,
      created_at: collaboration.created_at.iso8601,
      updated_at: collaboration.updated_at.iso8601
    }
  end
end