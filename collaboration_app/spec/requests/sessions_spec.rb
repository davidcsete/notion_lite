require 'rails_helper'

RSpec.describe "API Sessions", type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }
  
  describe "POST /api/v1/auth/login" do
    context "with valid credentials" do
      it "returns user data and sets session" do
        post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['message']).to eq('Successfully logged in!')
        expect(session[:user_id]).to eq(user.id)
      end
    end
    
    context "with invalid credentials" do
      it "returns error" do
        post '/api/v1/auth/login', params: { email: user.email, password: 'wrong_password' }
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid email or password')
        expect(session[:user_id]).to be_nil
      end
    end
  end
  
  describe "GET /api/v1/auth/me" do
    context "when logged in" do
      before do
        post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
      end
      
      it "returns current user data" do
        get '/api/v1/auth/me'
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        get '/api/v1/auth/me'
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Authentication required')
      end
    end
  end
  
  describe "DELETE /api/v1/auth/logout" do
    before do
      post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
    end
    
    it "logs out the user" do
      delete '/api/v1/auth/logout'
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['message']).to eq('Successfully logged out!')
      expect(session[:user_id]).to be_nil
    end
  end
end
