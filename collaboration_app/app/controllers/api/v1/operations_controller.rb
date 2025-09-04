class Api::V1::OperationsController < Api::V1::BaseController
  before_action :find_note
  before_action :require_note_access
  before_action :require_edit_access, except: [:index]

  def index
    # Only allow owners and editors to view operations
    user_role = @note.user_role(current_user)
    unless user_role == 'owner' || user_role == 'editor'
      render json: { error: 'Edit permission required' }, status: :forbidden
      return
    end

    begin
      operations = @note.operations.includes(:user).ordered
      
      if params[:since].present?
        since_time = Time.parse(params[:since])
        operations = operations.where('timestamp > ?', since_time)
      end
      
      render json: {
        operations: operations.map { |op| operation_json(op) },
        document_state: @note.document_state || {}
      }
    rescue ArgumentError
      render json: { error: 'Invalid timestamp format' }, status: :bad_request
    end
  end

  def create
    operation = @note.operations.build(operation_params)
    operation.user = current_user

    if operation.save
      render json: {
        operation: operation_json(operation),
        message: 'Operation created successfully!'
      }
    else
      render json: { errors: operation.errors.full_messages }, status: :unprocessable_entity
    end
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

  def require_edit_access
    require_edit_permission(@note)
  end

  def operation_params
    params.require(:operation).permit(:operation_type, :position, :content)
  end

  def operation_json(operation)
    {
      id: operation.id,
      type: operation.operation_type,
      position: operation.position,
      content: operation.content,
      user: {
        id: operation.user.id,
        name: operation.user.name,
        avatar_url: operation.user.avatar_url
      },
      timestamp: operation.timestamp.iso8601(3),
      applied: operation.applied
    }
  end
end