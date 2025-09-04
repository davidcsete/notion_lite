require 'rails_helper'

RSpec.describe Operation, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:operation_type) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).is_greater_than_or_equal_to(0) }
    it { should validate_inclusion_of(:applied).in_array([true, false]) }
    
    it 'validates presence of timestamp after initialization' do
      operation = build(:operation, timestamp: nil)
      expect(operation).to be_valid
      expect(operation.timestamp).to be_present
    end
  end

  describe 'associations' do
    it { should belong_to(:note) }
    it { should belong_to(:user) }
  end

  describe 'enums' do
    it { should define_enum_for(:operation_type).with_values(op_insert: 0, op_delete: 1, op_retain: 2) }
  end

  describe 'callbacks' do
    describe 'before_validation on create' do
      let(:operation) { build(:operation, timestamp: nil, applied: nil) }

      it 'sets timestamp when nil' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)
        
        operation.save
        expect(operation.timestamp).to eq(freeze_time)
      end

      it 'sets applied to false when nil' do
        operation.save
        expect(operation.applied).to be false
      end

      it 'does not override existing timestamp' do
        existing_time = 1.hour.ago
        operation.timestamp = existing_time
        operation.save
        expect(operation.timestamp).to eq(existing_time)
      end

      it 'does not override existing applied value' do
        operation.applied = true
        operation.save
        expect(operation.applied).to be true
      end
    end
  end

  describe 'scopes' do
    let(:note) { create(:note) }
    let(:other_note) { create(:note) }
    let!(:note_operation) { create(:operation, note: note) }
    let!(:other_operation) { create(:operation, note: other_note) }
    let!(:applied_operation) { create(:operation, :applied, note: note) }
    let!(:pending_operation) { create(:operation, note: note, applied: false) }

    describe '.for_note' do
      it 'returns operations for the specified note' do
        operations = Operation.for_note(note)
        expect(operations).to include(note_operation, applied_operation, pending_operation)
        expect(operations).not_to include(other_operation)
      end
    end

    describe '.applied' do
      it 'returns only applied operations' do
        expect(Operation.applied).to include(applied_operation)
        expect(Operation.applied).not_to include(pending_operation)
      end
    end

    describe '.pending' do
      it 'returns only pending operations' do
        expect(Operation.pending).to include(pending_operation)
        expect(Operation.pending).not_to include(applied_operation)
      end
    end

    describe '.ordered' do
      let!(:first_operation) { create(:operation, timestamp: 2.hours.ago) }
      let!(:second_operation) { create(:operation, timestamp: 1.hour.ago) }
      let!(:third_operation) { create(:operation, timestamp: Time.current) }

      it 'returns operations ordered by timestamp ascending' do
        ordered_operations = Operation.ordered
        expect(ordered_operations.first).to eq(first_operation)
        expect(ordered_operations.last).to eq(third_operation)
      end
    end

    describe '.recent' do
      let!(:first_operation) { create(:operation, timestamp: 2.hours.ago) }
      let!(:second_operation) { create(:operation, timestamp: 1.hour.ago) }
      let!(:third_operation) { create(:operation, timestamp: Time.current) }

      it 'returns operations ordered by timestamp descending' do
        recent_operations = Operation.recent
        expect(recent_operations.first).to eq(third_operation)
        expect(recent_operations.last).to eq(first_operation)
      end
    end
  end

  describe '#apply!' do
    let(:operation) { create(:operation, applied: false) }

    it 'sets applied to true' do
      operation.apply!
      expect(operation.applied).to be true
    end

    it 'persists the change' do
      operation.apply!
      operation.reload
      expect(operation.applied).to be true
    end
  end

  describe '#serializable_hash' do
    let(:user) { create(:user) }
    let(:operation) { create(:operation, :insert, user: user, timestamp: Time.parse('2024-01-01 12:00:00 UTC')) }

    it 'includes operation type as "type"' do
      hash = operation.serializable_hash
      expect(hash['type']).to eq('insert')
    end

    it 'includes user_id' do
      hash = operation.serializable_hash
      expect(hash['user_id']).to eq(user.id)
    end

    it 'includes timestamp in ISO8601 format with milliseconds' do
      hash = operation.serializable_hash
      expect(hash['timestamp']).to eq('2024-01-01T12:00:00.000Z')
    end

    it 'includes all other attributes' do
      hash = operation.serializable_hash
      expect(hash).to include('id', 'note_id', 'position', 'content', 'applied')
    end
  end

  describe 'operation types' do
    describe 'insert operation' do
      let(:operation) { create(:operation, :insert, content: 'Hello World', position: 10) }

      it 'has correct type' do
        expect(operation.op_insert?).to be true
        expect(operation.operation_type).to eq('op_insert')
      end

      it 'has content' do
        expect(operation.content).to eq('Hello World')
      end
    end

    describe 'delete operation' do
      let(:operation) { create(:operation, :delete, position: 5) }

      it 'has correct type' do
        expect(operation.op_delete?).to be true
        expect(operation.operation_type).to eq('op_delete')
      end
    end

    describe 'retain operation' do
      let(:operation) { create(:operation, :retain, position: 15) }

      it 'has correct type' do
        expect(operation.op_retain?).to be true
        expect(operation.operation_type).to eq('op_retain')
      end
    end
  end
end