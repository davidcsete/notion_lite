require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
  end

  describe 'associations' do
    it { should have_many(:owned_notes).class_name('Note').with_foreign_key('owner_id').dependent(:destroy) }
    it { should have_many(:collaborations).dependent(:destroy) }
    it { should have_many(:notes).through(:collaborations) }
    it { should have_many(:operations).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:user) { create(:user, email: 'test@example.com') }

    describe '.by_email' do
      it 'returns users with matching email' do
        expect(User.by_email('test@example.com')).to include(user)
      end

      it 'does not return users with different email' do
        expect(User.by_email('other@example.com')).not_to include(user)
      end
    end
  end

  describe '#accessible_notes' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:owned_note) { create(:note, owner: user) }
    let!(:collaborated_note) { create(:note, owner: other_user) }
    let!(:inaccessible_note) { create(:note, owner: other_user) }

    before do
      create(:collaboration, user: user, note: collaborated_note, role: 'editor')
    end

    it 'returns notes owned by the user' do
      expect(user.accessible_notes).to include(owned_note)
    end

    it 'returns notes the user collaborates on' do
      expect(user.accessible_notes).to include(collaborated_note)
    end

    it 'does not return notes the user has no access to' do
      expect(user.accessible_notes).not_to include(inaccessible_note)
    end

    it 'returns unique notes only' do
      # The user already has one collaboration, so accessible_notes should return unique results
      accessible_notes = user.accessible_notes
      note_ids = accessible_notes.pluck(:id)
      expect(note_ids.uniq.length).to eq(note_ids.length)
    end
  end

  describe 'password authentication' do
    let(:user) { create(:user, password: 'password123') }

    it 'authenticates with correct password' do
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      expect(user.authenticate('wrong_password')).to be_falsey
    end
  end
end