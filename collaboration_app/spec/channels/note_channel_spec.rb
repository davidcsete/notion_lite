require 'rails_helper'

RSpec.describe NoteChannel, type: :channel do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:note) { create(:note, owner: user) }
  let(:collaboration) { create(:collaboration, note: note, user: other_user, role: 'editor') }
  let(:mock_redis) { double('redis', hset: true, expire: true, hdel: true, hgetall: {}) }

  before do
    stub_connection current_user: user
    allow_any_instance_of(NoteChannel).to receive(:redis).and_return(mock_redis)
  end

  describe '#subscribed' do
    context 'when user has access to the note' do
      it 'successfully subscribes to the note stream' do
        subscribe(note_id: note.id)
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(note)
      end

      it 'broadcasts user joined event' do
        expect { subscribe(note_id: note.id) }.to have_broadcasted_to(note).with(
          hash_including(
            type: 'user_joined',
            user: hash_including(
              id: user.id,
              name: user.name,
              email: user.email
            )
          )
        )
      end
    end

    context 'when user does not have access to the note' do
      let(:unauthorized_note) { create(:note, owner: other_user) }

      it 'rejects the subscription' do
        subscribe(note_id: unauthorized_note.id)
        expect(subscription).to be_rejected
      end
    end

    context 'when note does not exist' do
      it 'raises an error' do
        expect { subscribe(note_id: 999) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#unsubscribed' do
    before do
      subscribe(note_id: note.id)
    end

    it 'broadcasts user left event' do
      expect { unsubscribe }.to have_broadcasted_to(note).with(
        hash_including(
          type: 'user_left',
          user_id: user.id
        )
      )
    end

    it 'removes user from presence tracking' do
      redis_key = "note:#{note.id}:users"
      expect(mock_redis).to receive(:hdel).with(redis_key, user.id)
      unsubscribe
    end
  end

  describe '#receive' do
    before do
      subscribe(note_id: note.id)
    end

    context 'when receiving an operation' do
      let(:operation_data) do
        {
          'type' => 'operation',
          'operation' => {
            'type' => 'insert',
            'position' => 0,
            'content' => 'Hello World'
          }
        }
      end

      context 'when user can edit the note' do
        it 'creates an operation record' do
          expect {
            perform :receive, operation_data
          }.to change(Operation, :count).by(1)

          operation = Operation.last
          expect(operation.note).to eq(note)
          expect(operation.user).to eq(user)
          expect(operation.operation_type).to eq('op_insert')
          expect(operation.position).to eq(0)
          expect(operation.content).to eq('Hello World')
        end

        it 'broadcasts the operation to other users' do
          expect {
            perform :receive, operation_data
          }.to have_broadcasted_to(note).with(
            hash_including(
              type: 'operation',
              operation: hash_including(
                type: 'insert',
                position: 0,
                content: 'Hello World',
                user_id: user.id,
                user_name: user.name
              )
            )
          )
        end

        it 'updates the note document state' do
          initial_version = note.document_state['version'] || 0
          perform :receive, operation_data
          
          note.reload
          expect(note.document_state['version']).to eq(initial_version + 1)
          expect(note.document_state['operations']).to include(
            hash_including(
              'type' => 'insert',
              'position' => 0,
              'content' => 'Hello World'
            )
          )
        end
      end

      context 'when user cannot edit the note (viewer role)' do
        let(:viewer_collaboration) { create(:collaboration, note: note, user: user, role: 'viewer') }
        
        before do
          # Change user to viewer role
          note.update!(owner: other_user)
          viewer_collaboration
          stub_connection current_user: user
          subscribe(note_id: note.id)
        end

        it 'does not create an operation record' do
          expect {
            perform :receive, operation_data
          }.not_to change(Operation, :count)
        end

        it 'does not broadcast the operation' do
          expect {
            perform :receive, operation_data
          }.not_to have_broadcasted_to(note)
        end
      end
    end

    context 'when receiving cursor update' do
      let(:cursor_data) do
        {
          'type' => 'cursor',
          'position' => 10,
          'selection' => { 'start' => 5, 'end' => 15 }
        }
      end

      it 'broadcasts cursor position to other users' do
        expect {
          perform :receive, cursor_data
        }.to have_broadcasted_to(note).with(
          type: 'cursor',
          user_id: user.id,
          user_name: user.name,
          position: 10,
          selection: { 'start' => 5, 'end' => 15 }
        )
      end
    end

    context 'when receiving typing indicator' do
      let(:typing_data) do
        {
          'type' => 'typing',
          'is_typing' => true
        }
      end

      it 'broadcasts typing status to other users' do
        expect {
          perform :receive, typing_data
        }.to have_broadcasted_to(note).with(
          type: 'typing',
          user_id: user.id,
          user_name: user.name,
          is_typing: true
        )
      end
    end
  end

  describe 'presence tracking' do

    it 'adds user to Redis presence set on subscribe' do
      redis_key = "note:#{note.id}:users"
      expect(mock_redis).to receive(:hset).with(redis_key, user.id, anything)
      expect(mock_redis).to receive(:expire).with(redis_key, 1.hour)
      
      subscribe(note_id: note.id)
    end

    it 'removes user from Redis presence set on unsubscribe' do
      subscribe(note_id: note.id)
      
      redis_key = "note:#{note.id}:users"
      expect(mock_redis).to receive(:hdel).with(redis_key, user.id)
      
      unsubscribe
    end
  end

  describe 'authorization' do
    context 'when user is note owner' do
      it 'allows access' do
        subscribe(note_id: note.id)
        expect(subscription).to be_confirmed
      end
    end

    context 'when user is a collaborator' do
      before do
        collaboration # Create collaboration
        stub_connection current_user: other_user
      end

      it 'allows access' do
        subscribe(note_id: note.id)
        expect(subscription).to be_confirmed
      end
    end

    context 'when user has no access' do
      let(:unauthorized_user) { create(:user) }
      
      before do
        stub_connection current_user: unauthorized_user
      end

      it 'rejects access' do
        subscribe(note_id: note.id)
        expect(subscription).to be_rejected
      end
    end
  end
end