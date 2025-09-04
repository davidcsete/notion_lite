require 'rails_helper'

RSpec.describe "API Operations", type: :request do
  let(:owner) { create(:user, password: 'password123') }
  let(:editor) { create(:user, password: 'password123') }
  let(:viewer) { create(:user, password: 'password123') }
  let(:note) { create(:note, owner: owner) }
  
  # Helper method to authenticate user in session
  def login_as(user)
    post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }
  end
  
  before do
    create(:collaboration, user: editor, note: note, role: :editor)
    create(:collaboration, user: viewer, note: note, role: :viewer)
  end
  
  describe "GET /api/v1/notes/:note_id/operations" do
    context "when logged in as owner" do
      before { login_as(owner) }
      
      it "returns operations for the note" do
        operation1 = create(:operation, note: note, user: owner, operation_type: 'op_insert', position: 0, content: 'Hello')
        operation2 = create(:operation, note: note, user: editor, operation_type: 'op_insert', position: 5, content: ' World')
        
        get "/api/v1/notes/#{note.id}/operations"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['operations']).to be_an(Array)
        expect(json_response['operations'].length).to eq(2)
        expect(json_response['document_state']).to be_present
        
        # Check operation details
        op1 = json_response['operations'].find { |op| op['user']['id'] == owner.id }
        expect(op1['type']).to eq('op_insert')
        expect(op1['position']).to eq(0)
        expect(op1['content']).to eq('Hello')
      end
      
      it "returns operations since specific timestamp" do
        old_operation = create(:operation, note: note, user: owner, timestamp: 2.hours.ago)
        recent_operation = create(:operation, note: note, user: editor, timestamp: 30.minutes.ago)
        
        get "/api/v1/notes/#{note.id}/operations", params: { since: 1.hour.ago.iso8601 }
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['operations'].length).to eq(1)
        expect(json_response['operations'][0]['user']['id']).to eq(editor.id)
      end
      
      it "returns bad request for invalid timestamp" do
        get "/api/v1/notes/#{note.id}/operations", params: { since: 'invalid-timestamp' }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid timestamp format')
      end
    end
    
    context "when logged in as editor" do
      before { login_as(editor) }
      
      it "allows viewing operations" do
        create(:operation, note: note, user: owner)
        
        get "/api/v1/notes/#{note.id}/operations"
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['operations']).to be_an(Array)
      end
    end
    
    context "when logged in as viewer" do
      before { login_as(viewer) }
      
      it "denies access" do
        get "/api/v1/notes/#{note.id}/operations"
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Edit permission required')
      end
    end
    
    context "when not authorized" do
      let(:unauthorized_user) { create(:user, password: 'password123') }
      before { login_as(unauthorized_user) }
      
      it "denies access" do
        get "/api/v1/notes/#{note.id}/operations"
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        get "/api/v1/notes/#{note.id}/operations"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe "POST /api/v1/notes/:note_id/operations" do
    context "when logged in as owner" do
      before { login_as(owner) }
      
      let(:valid_params) do
        {
          operation: {
            operation_type: 'op_insert',
            position: 0,
            content: 'Hello World'
          }
        }
      end
      
      it "creates a new operation" do
        expect {
          post "/api/v1/notes/#{note.id}/operations", params: valid_params
        }.to change(Operation, :count).by(1)
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['operation']['type']).to eq('op_insert')
        expect(json_response['operation']['position']).to eq(0)
        expect(json_response['operation']['content']).to eq('Hello World')
        expect(json_response['operation']['user']['id']).to eq(owner.id)
        expect(json_response['message']).to eq('Operation created successfully!')
        
        operation = Operation.last
        expect(operation.user).to eq(owner)
        expect(operation.note).to eq(note)
        expect(operation.operation_type).to eq('op_insert')
        expect(operation.timestamp).to be_present
      end
      
      it "returns validation errors for invalid data" do
        invalid_params = valid_params.dup
        invalid_params[:operation] = invalid_params[:operation].dup
        invalid_params[:operation][:operation_type] = ''
        
        expect {
          post "/api/v1/notes/#{note.id}/operations", params: invalid_params
        }.not_to change(Operation, :count)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
      end
    end
    
    context "when logged in as editor" do
      before { login_as(editor) }
      
      it "allows creating operations" do
        expect {
          post "/api/v1/notes/#{note.id}/operations", params: {
            operation: {
              operation_type: 'op_delete',
              position: 5,
              content: 'text'
            }
          }
        }.to change(Operation, :count).by(1)
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['operation']['user']['id']).to eq(editor.id)
      end
    end
    
    context "when logged in as viewer" do
      before { login_as(viewer) }
      
      it "denies access" do
        expect {
          post "/api/v1/notes/#{note.id}/operations", params: {
            operation: {
              operation_type: 'op_insert',
              position: 0,
              content: 'test'
            }
          }
        }.not_to change(Operation, :count)
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Edit permission required')
      end
    end
    
    context "when not authorized" do
      let(:unauthorized_user) { create(:user, password: 'password123') }
      before { login_as(unauthorized_user) }
      
      it "denies access" do
        post "/api/v1/notes/#{note.id}/operations", params: {
          operation: {
            operation_type: 'op_insert',
            position: 0,
            content: 'test'
          }
        }
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized" do
        post "/api/v1/notes/#{note.id}/operations", params: {
          operation: {
            operation_type: 'op_insert',
            position: 0,
            content: 'test'
          }
        }
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end