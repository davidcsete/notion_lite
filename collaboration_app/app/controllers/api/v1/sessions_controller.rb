class Api::V1::SessionsController < Api::V1::BaseController
  skip_before_action :require_login, only: [:create]
  
  def create
    user = User.find_by(email: params[:email]&.downcase)
    
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      render_success({ user: user_json(user) }, 'Successfully logged in!')
    else
      render_error('Invalid email or password', :unauthorized)
    end
  end
  
  def destroy
    session[:user_id] = nil
    render_success({}, 'Successfully logged out!')
  end
  
  def show
    render_success({ user: user_json(current_user) })
  end
  
  private
  
  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      avatar_url: user.avatar_url
    }
  end
end