module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Get user from session or token
      if request.session[:user_id] && (user = User.find_by(id: request.session[:user_id]))
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end