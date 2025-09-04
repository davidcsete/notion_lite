class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  protected
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end
  
  def logged_in?
    !!current_user
  end
  
  def require_login
    unless logged_in?
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end
  
  def require_owner_or_collaborator(note)
    unless note.accessible_by?(current_user)
      render json: { error: 'Access denied' }, status: :forbidden
    end
  end
  
  def require_edit_permission(note)
    user_role = note.user_role(current_user)
    unless user_role == 'owner' || user_role == 'editor'
      render json: { error: 'Edit permission required' }, status: :forbidden
    end
  end
end
