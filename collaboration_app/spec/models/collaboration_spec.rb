require 'rails_helper'

RSpec.describe Collaboration, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:role) }
    it { should define_enum_for(:role).with_values(editor: 0, viewer: 1) }
    
    describe 'uniqueness validation' do
      let(:user) { create(:user) }
      let(:note) { create(:note) }
      let!(:existing_collaboration) { create(:collaboration, user: user, note: note) }

      it 'validates uniqueness of user_id scoped to note_id' do
        duplicate_collaboration = build(:collaboration, user: user, note: note)
        expect(duplicate_collaboration).not_to be_valid
        expect(duplicate_collaboration.errors[:user_id]).to include("User is already a collaborator on this note")
      end

      it 'allows same user to collaborate on different notes' do
        other_note = create(:note)
        collaboration = build(:collaboration, user: user, note: other_note)
        expect(collaboration).to be_valid
      end

      it 'allows different users to collaborate on same note' do
        other_user = create(:user)
        collaboration = build(:collaboration, user: other_user, note: note)
        expect(collaboration).to be_valid
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:note) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(editor: 0, viewer: 1) }
  end

  describe 'scopes' do
    let(:note) { create(:note) }
    let!(:editor_collaboration) { create(:collaboration, :editor, note: note) }
    let!(:viewer_collaboration) { create(:collaboration, :viewer, note: note) }

    describe '.editors' do
      it 'returns only editor collaborations' do
        expect(Collaboration.editors).to include(editor_collaboration)
        expect(Collaboration.editors).not_to include(viewer_collaboration)
      end
    end

    describe '.viewers' do
      it 'returns only viewer collaborations' do
        expect(Collaboration.viewers).to include(viewer_collaboration)
        expect(Collaboration.viewers).not_to include(editor_collaboration)
      end
    end

    describe '.for_note' do
      let(:other_note) { create(:note) }
      let!(:other_collaboration) { create(:collaboration, note: other_note) }

      it 'returns collaborations for the specified note' do
        collaborations = Collaboration.for_note(note)
        expect(collaborations).to include(editor_collaboration, viewer_collaboration)
        expect(collaborations).not_to include(other_collaboration)
      end
    end

    describe '.for_user' do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let!(:user_collaboration) { create(:collaboration, user: user) }
      let!(:other_collaboration) { create(:collaboration, user: other_user) }

      it 'returns collaborations for the specified user' do
        collaborations = Collaboration.for_user(user)
        expect(collaborations).to include(user_collaboration)
        expect(collaborations).not_to include(other_collaboration)
      end
    end
  end

  describe '#can_edit?' do
    it 'returns true for editors' do
      collaboration = build(:collaboration, :editor)
      expect(collaboration.can_edit?).to be true
    end

    it 'returns false for viewers' do
      collaboration = build(:collaboration, :viewer)
      expect(collaboration.can_edit?).to be false
    end
  end

  describe '#can_view?' do
    it 'returns true for editors' do
      collaboration = build(:collaboration, :editor)
      expect(collaboration.can_view?).to be true
    end

    it 'returns true for viewers' do
      collaboration = build(:collaboration, :viewer)
      expect(collaboration.can_view?).to be true
    end
  end

  describe 'role methods' do
    let(:editor_collaboration) { create(:collaboration, :editor) }
    let(:viewer_collaboration) { create(:collaboration, :viewer) }

    it 'provides editor? method' do
      expect(editor_collaboration.editor?).to be true
      expect(viewer_collaboration.editor?).to be false
    end

    it 'provides viewer? method' do
      expect(viewer_collaboration.viewer?).to be true
      expect(editor_collaboration.viewer?).to be false
    end
  end
end