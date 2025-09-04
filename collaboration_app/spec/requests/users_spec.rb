require 'rails_helper'

RSpec.describe "API Users", type: :request do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }
  
  describe "POST /api/v1/users" do
    let(:valid_params) do
      {
        user: {
          name: 'Jane Doe',
          email: 'jane@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end
    
    context "with valid parameters" do
      it "creates user and returns user data" do
        expect {
          post '/api/v1/users', params: valid_params
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['email']).to eq('jane@example.com')
        expect(json_response['message']).to eq('Account created successfully!')
        
        # Should be logged in
        new_user = User.last
        expect(session[:user_id]).to eq(new_user.id)
      end
    end
    
    context "with invalid parameters" do
      it "returns validation errors" do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = 'invalid_email'
        
        expect {
          post '/api/v1/users', params: invalid_params
        }.not_to change(User, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Email is invalid')
      end
    end
  end
  
  describe "GET /api/v1/users/:id" do
    context "when logged in" do
      before do
        post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
      end
      
      it "returns own profile" do
        get "/api/v1/users/#{user.id}"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
      end
      
      it "returns collaborator's profile" do
        other_user = create(:user)
        note = create(:note, owner: user)
        create(:collaboration, user: other_user, note: note, role: :editor)
        
        get "/api/v1/users/#{other_user.id}"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['id']).to eq(other_user.id)
      end
      
      it "denies access to non-collaborator's profile" do
        other_user = create(:user)
        
        get "/api/v1/users/#{other_user.id}"
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        get "/api/v1/users/#{user.id}"
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Authentication required')
      end
    end
  end
  
  describe "PUT /api/v1/users/:id" do
    context "when logged in" do
      before do
        post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
      end
      
      it "updates user profile" do
        put "/api/v1/users/#{user.id}", params: {
          user: { name: 'Updated Name', avatar_url: 'https://example.com/new-avatar.jpg' }
        }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['user']['name']).to eq('Updated Name')
        expect(json_response['user']['avatar_url']).to eq('https://example.com/new-avatar.jpg')
        expect(json_response['message']).to eq('Profile updated successfully!')
        
        user.reload
        expect(user.name).to eq('Updated Name')
      end
      
      it "returns validation errors for invalid data" do
        put "/api/v1/users/#{user.id}", params: {
          user: { name: '' }
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Name can\'t be blank')
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        put "/api/v1/users/#{user.id}", params: { user: { name: 'New Name' } }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/users/search" do
    let!(:alice) { create(:user, name: 'Alice Johnson', email: 'alice@example.com') }
    let!(:bob) { create(:user, name: 'Bob Smith', email: 'bob@example.com') }
    let!(:charlie) { create(:user, name: 'Charlie Brown', email: 'charlie@test.com') }
    
    context "when logged in" do
      before do
        post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
      end
      
      it "searches users by name" do
        get '/api/v1/users/search', params: { q: 'Alice' }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(1)
        expect(json_response['users'][0]['name']).to eq('Alice Johnson')
        expect(json_response['users'][0]['email']).to eq('alice@example.com')
      end
      
      it "searches users by email" do
        get '/api/v1/users/search', params: { q: 'bob@' }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(1)
        expect(json_response['users'][0]['name']).to eq('Bob Smith')
      end
      
      it "returns multiple matching users" do
        get '/api/v1/users/search', params: { q: 'example.com' }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['users'].length).to eq(2)
        user_names = json_response['users'].map { |u| u['name'] }
        expect(user_names).to include('Alice Johnson', 'Bob Smith')
      end
      
      it "excludes current user from results" do
        get '/api/v1/users/search', params: { q: user.email }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['users']).to be_empty
      end
      
      it "returns empty array for short queries" do
        get '/api/v1/users/search', params: { q: 'a' }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['users']).to be_empty
      end
      
      it "returns empty array for blank queries" do
        get '/api/v1/users/search', params: { q: '' }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['users']).to be_empty
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        get '/api/v1/users/search', params: { q: 'Alice' }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
