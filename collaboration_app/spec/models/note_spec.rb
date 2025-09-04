require 'rails_helper'

RSpec.describe Note, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    
    it 'validates presence of content after initialization' do
      note = build(:note, content: nil)
      expect(note).to be_valid
      expect(note.content).to eq({ "type" => "doc", "content" => [] })
    end
    
    it 'validates presence of document_state after initialization' do
      note = build(:note, document_state: nil)
      expect(note).to be_valid
      expect(note.document_state).to eq({ "version" => 0, "operations" => [] })
    end
  end

  describe 'associations' do
    it { should belong_to(:owner).class_name('User') }
    it { should have_many(:collaborations).dependent(:destroy) }
    it { should have_many(:collaborators).through(:collaborations).source(:user) }
    it { should have_many(:operations).dependent(:destroy) }
  end

  describe 'callbacks' do
    describe 'before_validation on create' do
      let(:note) { build(:note, content: nil, document_state: nil) }

      it 'initializes content when nil' do
        note.save
        expect(note.content).to eq({ "type" => "doc", "content" => [] })
      end

      it 'initializes document_state when nil' do
        note.save
        expect(note.document_state).to eq({ "version" => 0, "operations" => [] })
      end

      it 'does not override existing content' do
        existing_content = { "type" => "doc", "content" => [{ "type" => "text", "text" => "existing" }] }
        note.content = existing_content
        note.save
        expect(note.content).to eq(existing_content)
      end

      it 'does not override existing document_state' do
        existing_state = { "version" => 5, "operations" => ["op1"] }
        note.document_state = existing_state
        note.save
        expect(note.document_state).to eq(existing_state)
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:owned_note) { create(:note, owner: user) }
    let!(:collaborated_note) { create(:note, owner: other_user) }
    let!(:inaccessible_note) { create(:note, owner: other_user) }

    before do
      create(:collaboration, user: user, note: collaborated_note, role: 'editor')
    end

    describe '.accessible_by' do
      it 'returns notes owned by the user' do
        expect(Note.accessible_by(user)).to include(owned_note)
      end

      it 'returns notes the user collaborates on' do
        expect(Note.accessible_by(user)).to include(collaborated_note)
      end

      it 'does not return notes the user has no access to' do
        expect(Note.accessible_by(user)).not_to include(inaccessible_note)
      end
    end
  end

  describe '#user_role' do
    let(:owner) { create(:user) }
    let(:editor) { create(:user) }
    let(:viewer) { create(:user) }
    let(:non_collaborator) { create(:user) }
    let(:note) { create(:note, owner: owner) }

    before do
      create(:collaboration, user: editor, note: note, role: 'editor')
      create(:collaboration, user: viewer, note: note, role: 'viewer')
    end

    it 'returns "owner" for the note owner' do
      expect(note.user_role(owner)).to eq('owner')
    end

    it 'returns the collaboration role for collaborators' do
      expect(note.user_role(editor)).to eq('editor')
      expect(note.user_role(viewer)).to eq('viewer')
    end

    it 'returns nil for non-collaborators' do
      expect(note.user_role(non_collaborator)).to be_nil
    end
  end

  describe '#accessible_by?' do
    let(:owner) { create(:user) }
    let(:collaborator) { create(:user) }
    let(:non_collaborator) { create(:user) }
    let(:note) { create(:note, owner: owner) }

    before do
      create(:collaboration, user: collaborator, note: note, role: 'editor')
    end

    it 'returns true for the owner' do
      expect(note.accessible_by?(owner)).to be true
    end

    it 'returns true for collaborators' do
      expect(note.accessible_by?(collaborator)).to be true
    end

    it 'returns false for non-collaborators' do
      expect(note.accessible_by?(non_collaborator)).to be false
    end
  end

  describe 'content and document_state as JSONB' do
    let(:note) { create(:note) }

    it 'stores content as JSON' do
      complex_content = {
        "type" => "doc",
        "content" => [
          {
            "type" => "heading",
            "attrs" => { "level" => 1 },
            "content" => [{ "type" => "text", "text" => "Title" }]
          },
          {
            "type" => "paragraph",
            "content" => [{ "type" => "text", "text" => "Content" }]
          }
        ]
      }
      
      note.update!(content: complex_content)
      note.reload
      
      expect(note.content).to eq(complex_content)
    end

    it 'stores document_state as JSON' do
      complex_state = {
        "version" => 10,
        "operations" => [
          { "type" => "insert", "position" => 0, "text" => "Hello" },
          { "type" => "retain", "count" => 5 }
        ]
      }
      
      note.update!(document_state: complex_state)
      note.reload
      
      expect(note.document_state).to eq(complex_state)
    end
  end
end