require 'rails_helper'

RSpec.describe "API Collaborations", type: :request do
  let(:owner) { create(:user, email: 'owner@example.com', password: 'password123') }
  let(:collaborator) { create(:user, email: 'collaborator@example.com', password: 'password123') }
  let(:other_user) { create(:user, email: 'other@example.com', password: 'password123') }
  let(:note) { create(:note, owner: owner) }
  
  # Helper method to authenticate user in session
  def login_as(user)
    post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
  end
  
  describe "GET /api/v1/notes/:note_id/collaborations" do
    context "when logged in as owner" do
      before { login_as(owner) }
      
      it "returns all collaborations for the note" do
        collaboration1 = create(:collaboration, user: collaborator, note: note, role: :editor)
        collaboration2 = create(:collaboration, user: other_user, note: note, role: :viewer)
        
        get "/api/v1/notes/#{note.id}/collaborations"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['collaborations']).to be_an(Array)
        expect(json_response['collaborations'].length).to eq(2)
        
        roles = json_response['collaborations'].map { |c| c['role'] }
        expect(roles).to include('editor', 'viewer')
      end
      
      it "returns empty array when no collaborations" do
        get "/api/v1/notes/#{note.id}/collaborations"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['collaborations']).to eq([])
      end
    end
    
    context "when logged in as collaborator" do
      before do
        login_as(collaborator)
        create(:collaboration, user: collaborator, note: note, role: :editor)
      end
      
      it "allows viewing collaborations" do
        get "/api/v1/notes/#{note.id}/collaborations"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['collaborations']).to be_an(Array)
      end
    end
    
    context "when not authorized" do
      before { login_as(other_user) }
      
      it "denies access" do
        get "/api/v1/notes/#{note.id}/collaborations"
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        get "/api/v1/notes/#{note.id}/collaborations"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "POST /api/v1/notes/:note_id/collaborations" do
    context "when logged in as owner" do
      before { login_as(owner) }
      
      it "creates a new collaboration" do
        expect {
          post "/api/v1/notes/#{note.id}/collaborations", params: {
            email: collaborator.email,
            role: 'editor'
          }
        }.to change(Collaboration, :count).by(1)
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['collaboration']['user']['email']).to eq(collaborator.email)
        expect(json_response['collaboration']['role']).to eq('editor')
        expect(json_response['message']).to eq('Collaborator added successfully!')
        
        collaboration = Collaboration.last
        expect(collaboration.user).to eq(collaborator)
        expect(collaboration.note).to eq(note)
        expect(collaboration.role).to eq('editor')
      end
      
      it "creates collaboration with default viewer role" do
        post "/api/v1/notes/#{note.id}/collaborations", params: {
          email: collaborator.email
        }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['collaboration']['role']).to eq('viewer')
      end
      
      it "returns error for non-existent user" do
        expect {
          post "/api/v1/notes/#{note.id}/collaborations", params: {
            email: 'nonexistent@example.com',
            role: 'editor'
          }
        }.not_to change(Collaboration, :count)
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
      end
      
      it "returns error when trying to add owner as collaborator" do
        expect {
          post "/api/v1/notes/#{note.id}/collaborations", params: {
            email: owner.email,
            role: 'editor'
          }
        }.not_to change(Collaboration, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Cannot add owner as collaborator')
      end
      
      it "returns validation errors for duplicate collaboration" do
        create(:collaboration, user: collaborator, note: note, role: :viewer)
        
        expect {
          post "/api/v1/notes/#{note.id}/collaborations", params: {
            email: collaborator.email,
            role: 'editor'
          }
        }.not_to change(Collaboration, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('User User is already a collaborator on this note')
      end
    end
    
    context "when logged in as collaborator" do
      before do
        login_as(collaborator)
        create(:collaboration, user: collaborator, note: note, role: :editor)
      end
      
      it "denies access" do
        post "/api/v1/notes/#{note.id}/collaborations", params: {
          email: other_user.email,
          role: 'viewer'
        }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Only the owner can manage collaborators')
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        post "/api/v1/notes/#{note.id}/collaborations", params: {
          email: collaborator.email,
          role: 'editor'
        }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "PUT /api/v1/notes/:note_id/collaborations/:id" do
    context "when logged in as owner" do
      let(:collaboration) { create(:collaboration, user: collaborator, note: note, role: :viewer) }
      before { login_as(owner) }
      
      it "updates collaboration role" do
        put "/api/v1/notes/#{note.id}/collaborations/#{collaboration.id}", params: {
          collaboration: { role: 'editor' }
        }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['collaboration']['role']).to eq('editor')
        expect(json_response['message']).to eq('Collaboration updated successfully!')
        
        collaboration.reload
        expect(collaboration.role).to eq('editor')
      end
      
      it "returns validation errors for invalid role" do
        put "/api/v1/notes/#{note.id}/collaborations/#{collaboration.id}", params: {
          collaboration: { role: 'invalid_role' }
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
      end
    end
    
    context "when logged in as collaborator" do
      let(:collaboration) { create(:collaboration, user: other_user, note: note, role: :viewer) }
      before do
        login_as(collaborator)
        create(:collaboration, user: collaborator, note: note, role: :editor)
      end
      
      it "denies access" do
        put "/api/v1/notes/#{note.id}/collaborations/#{collaboration.id}", params: {
          collaboration: { role: 'editor' }
        }
        
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context "when not logged in" do
      let(:collaboration) { create(:collaboration, user: collaborator, note: note, role: :viewer) }
      
      it "returns unauthorized" do
        put "/api/v1/notes/#{note.id}/collaborations/#{collaboration.id}", params: {
          collaboration: { role: 'editor' }
        }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "DELETE /api/v1/notes/:note_id/collaborations/:id" do
    context "when logged in as owner" do
      let(:collaboration) { create(:collaboration, user: collaborator, note: note, role: :viewer) }
      before { login_as(owner) }
      
      it "removes collaboration" do
        collaboration_id = collaboration.id
        
        expect {
          delete "/api/v1/notes/#{note.id}/collaborations/#{collaboration_id}"
        }.to change(Collaboration, :count).by(-1)
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Collaborator removed successfully!')
        
        expect(Collaboration.find_by(id: collaboration_id)).to be_nil
      end
    end
    
    context "when logged in as collaborator" do
      let(:collaboration) { create(:collaboration, user: other_user, note: note, role: :viewer) }
      before do
        login_as(collaborator)
        create(:collaboration, user: collaborator, note: note, role: :editor)
      end
      
      it "denies access" do
        collaboration_id = collaboration.id
        
        expect {
          delete "/api/v1/notes/#{note.id}/collaborations/#{collaboration_id}"
        }.not_to change(Collaboration, :count)
        
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context "when not logged in" do
      let(:collaboration) { create(:collaboration, user: collaborator, note: note, role: :viewer) }
      
      it "returns unauthorized" do
        delete "/api/v1/notes/#{note.id}/collaborations/#{collaboration.id}"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end