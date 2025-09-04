class Api::V1::UsersController < Api::V1::BaseController
  skip_before_action :require_login, only: [:create]
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      session[:user_id] = @user.id
      render json: { user: user_json(@user), message: 'Account created successfully!' }, status: :created
    else
      render_errors(@user.errors.full_messages)
    end
  end
  
  def show
    user = User.find(params[:id])
    
    # Users can only view their own profile or profiles of users they collaborate with
    unless user == current_user || users_collaborate?(current_user, user)
      render_error('Access denied', :forbidden)
      return
    end
    
    render_success({ user: user_json(user) })
  rescue ActiveRecord::RecordNotFound
    render_error('User not found', :not_found)
  end
  
  def update
    @user = current_user
    
    if @user.update(user_update_params)
      render_success({ user: user_json(@user) }, 'Profile updated successfully!')
    else
      render_errors(@user.errors.full_messages)
    end
  end
  
  def search
    query = params[:q]&.strip
    
    if query.blank? || query.length < 2
      render_success({ users: [] })
      return
    end
    
    # Search users by name or email, excluding current user
    users = User.where.not(id: current_user.id)
                .where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
                .limit(10)
                .order(:name)
    
    render_success({ users: users.map { |user| user_json(user) } })
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :avatar_url)
  end
  
  def user_update_params
    params.require(:user).permit(:name, :avatar_url, :password, :password_confirmation)
  end
  
  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      avatar_url: user.avatar_url
    }
  end
  
  def users_collaborate?(user1, user2)
    # Check if two users collaborate on any notes
    user1_note_ids = user1.accessible_notes.pluck(:id)
    user2_note_ids = user2.accessible_notes.pluck(:id)
    (user1_note_ids & user2_note_ids).any?
  end
end