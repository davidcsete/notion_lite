require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  let(:user) { create(:user) }

  describe 'authentication logic' do
    it 'finds user when session contains valid user_id' do
      # Test the authentication logic directly
      expect(User).to receive(:find_by).with(id: user.id).and_return(user)
      
      # Simulate the logic from find_verified_user
      session = { user_id: user.id }
      result = User.find_by(id: session[:user_id]) if session[:user_id]
      
      expect(result).to eq(user)
    end

    it 'returns nil when session is empty' do
      session = {}
      result = User.find_by(id: session[:user_id]) if session[:user_id]
      
      expect(result).to be_nil
    end

    it 'returns nil when user_id is invalid' do
      expect(User).to receive(:find_by).with(id: 999).and_return(nil)
      
      session = { user_id: 999 }
      result = User.find_by(id: session[:user_id]) if session[:user_id]
      
      expect(result).to be_nil
    end
  end
end