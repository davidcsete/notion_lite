require 'rails_helper'

RSpec.describe "API::V1::Notes", type: :request do
  let(:user) { create(:user, password: 'password123') }
  let(:other_user) { create(:user, password: 'password123') }
  let(:note) { create(:note, owner: user, title: 'Test Note', content: { 'text' => 'Hello world' }) }
  
  # Helper method to authenticate user in session
  def login_as(user)
    post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
  end
  
  describe "GET /api/v1/notes" do
    context "when authenticated" do
      before { login_as(user) }
      
      it "returns user's accessible notes" do
        owned_note = create(:note, owner: user, title: 'My Note')
        shared_note = create(:note, owner: other_user, title: 'Shared Note')
        create(:collaboration, user: user, note: shared_note, role: :viewer)
        
        get '/api/v1/notes'
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['notes']).to be_an(Array)
        expect(json_response['notes'].length).to eq(2)
        
        note_titles = json_response['notes'].map { |n| n['title'] }
        expect(note_titles).to include('My Note', 'Shared Note')
      end
      
      it "includes note metadata" do
        note = create(:note, owner: user, title: 'Test Note')
        create(:collaboration, user: other_user, note: note, role: :editor)
        
        get '/api/v1/notes'
        
        json_response = JSON.parse(response.body)
        note_data = json_response['notes'].first
        
        expect(note_data).to include(
          'id' => note.id,
          'title' => 'Test Note',
          'user_role' => 'owner',
          'collaborators_count' => 1
        )
        expect(note_data['owner']).to include(
          'id' => user.id,
          'name' => user.name
        )
      end
    end
    
    context "when not authenticated" do
      it "returns unauthorized" do
        get '/api/v1/notes'
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Authentication required')
      end
    end
  end
  
  describe "GET /api/v1/notes/:id" do
    context "when authenticated and authorized" do
      before { login_as(user) }
      
      it "returns note details for owner" do
        get "/api/v1/notes/#{note.id}"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        
        expect(json_response['note']).to include(
          'id' => note.id,
          'title' => 'Test Note',
          'content' => { 'text' => 'Hello world' },
          'user_role' => 'owner'
        )
      end
      
      it "returns note details for collaborator" do
        collaboration = create(:collaboration, user: user, note: note, role: :editor)
        note.update!(owner: other_user)
        
        get "/api/v1/notes/#{note.id}"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['note']['user_role']).to eq('editor')
      end
      
      it "includes collaborators list" do
        create(:collaboration, user: other_user, note: note, role: :viewer)
        
        get "/api/v1/notes/#{note.id}"
        
        json_response = JSON.parse(response.body)
        collaborators = json_response['note']['collaborators']
        
        expect(collaborators).to be_an(Array)
        expect(collaborators.length).to eq(1)
        expect(collaborators.first).to include(
          'id' => other_user.id,
          'name' => other_user.name,
          'role' => 'viewer'
        )
      end
    end
    
    context "when not authorized" do
      before { login_as(other_user) }
      
      it "returns forbidden for non-accessible note" do
        get "/api/v1/notes/#{note.id}"
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end
    
    context "when note doesn't exist" do
      before { login_as(user) }
      
      it "returns not found" do
        get "/api/v1/notes/99999"
        
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Note not found')
      end
    end
  end
  
  describe "POST /api/v1/notes" do
    context "when authenticated" do
      before { login_as(user) }
      
      it "creates a new note" do
        note_params = {
          note: {
            title: 'New Note',
            content: { 'text' => 'This is a new note' }
          }
        }
        
        expect {
          post '/api/v1/notes', params: note_params
        }.to change(Note, :count).by(1)
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        
        expect(json_response['note']).to include(
          'title' => 'New Note',
          'user_role' => 'owner'
        )
        expect(json_response['message']).to eq('Note created successfully!')
        
        created_note = Note.last
        expect(created_note.owner).to eq(user)
        expect(created_note.content).to eq({ 'text' => 'This is a new note' })
      end
      
      it "creates note with empty content if not provided" do
        note_params = {
          note: {
            title: 'Empty Note'
          }
        }
        
        post '/api/v1/notes', params: note_params
        
        expect(response).to have_http_status(:success)
        created_note = Note.last
        expect(created_note.content).to eq({ "type" => "doc", "content" => [] })
      end
      
      it "returns validation errors for invalid data" do
        note_params = {
          note: {
            title: '' # Empty title should be invalid
          }
        }
        
        expect {
          post '/api/v1/notes', params: note_params
        }.not_to change(Note, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end
    
    context "when not authenticated" do
      it "returns unauthorized" do
        post '/api/v1/notes', params: { note: { title: 'Test' } }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "PUT /api/v1/notes/:id" do
    context "when authenticated and authorized" do
      before { login_as(user) }
      
      it "updates note as owner" do
        update_params = {
          note: {
            title: 'Updated Title',
            content: { 'text' => 'Updated content' }
          }
        }
        
        put "/api/v1/notes/#{note.id}", params: update_params
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        
        expect(json_response['note']).to include(
          'title' => 'Updated Title'
        )
        expect(json_response['message']).to eq('Note updated successfully!')
        
        note.reload
        expect(note.title).to eq('Updated Title')
        expect(note.content).to eq({ 'text' => 'Updated content' })
      end
      
      it "updates note as editor" do
        note.update!(owner: other_user)
        create(:collaboration, user: user, note: note, role: :editor)
        
        update_params = {
          note: {
            title: 'Editor Update'
          }
        }
        
        put "/api/v1/notes/#{note.id}", params: update_params
        
        expect(response).to have_http_status(:success)
        note.reload
        expect(note.title).to eq('Editor Update')
      end
      
      it "returns validation errors for invalid data" do
        update_params = {
          note: {
            title: ''
          }
        }
        
        put "/api/v1/notes/#{note.id}", params: update_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Title can't be blank")
      end
    end
    
    context "when not authorized to edit" do
      before { login_as(other_user) }
      
      it "returns forbidden for viewer" do
        create(:collaboration, user: other_user, note: note, role: :viewer)
        
        put "/api/v1/notes/#{note.id}", params: { note: { title: 'Hacked' } }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Edit permission required')
      end
      
      it "returns forbidden for non-collaborator" do
        put "/api/v1/notes/#{note.id}", params: { note: { title: 'Hacked' } }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Edit permission required')
      end
    end
  end
  
  describe "DELETE /api/v1/notes/:id" do
    context "when authenticated as owner" do
      before { login_as(user) }
      
      it "deletes the note" do
        note_id = note.id
        
        expect {
          delete "/api/v1/notes/#{note_id}"
        }.to change(Note, :count).by(-1)
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Note deleted successfully!')
        
        expect(Note.find_by(id: note_id)).to be_nil
      end
      
      it "deletes associated collaborations" do
        create(:collaboration, user: other_user, note: note, role: :editor)
        
        expect {
          delete "/api/v1/notes/#{note.id}"
        }.to change(Collaboration, :count).by(-1)
      end
    end
    
    context "when not owner" do
      before { login_as(other_user) }
      
      it "returns forbidden for editor" do
        create(:collaboration, user: other_user, note: note, role: :editor)
        
        expect {
          delete "/api/v1/notes/#{note.id}"
        }.not_to change(Note, :count)
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Only the owner can delete this note')
      end
      
      it "returns forbidden for non-collaborator" do
        expect {
          delete "/api/v1/notes/#{note.id}"
        }.not_to change(Note, :count)
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Edit permission required')
      end
    end
  end
end