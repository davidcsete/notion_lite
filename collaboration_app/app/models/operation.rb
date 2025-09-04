class Operation < ApplicationRecord
  belongs_to :note
  belongs_to :user

  # Enums
  enum :operation_type, { op_insert: 0, op_delete: 1, op_retain: 2 }

  # Validations
  validates :operation_type, presence: true, inclusion: { in: operation_types.keys }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :timestamp, presence: true
  validates :applied, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :set_timestamp, on: :create
  before_validation :set_applied_default, on: :create

  # Scopes
  scope :for_note, ->(note) { where(note: note) }
  scope :applied, -> { where(applied: true) }
  scope :pending, -> { where(applied: false) }
  scope :ordered, -> { order(:timestamp) }
  scope :recent, -> { order(timestamp: :desc) }

  def apply!
    update!(applied: true)
  end

  def serializable_hash(options = {})
    type_mapping = { 'op_insert' => 'insert', 'op_delete' => 'delete', 'op_retain' => 'retain' }
    super(options).merge(
      'type' => type_mapping[operation_type] || operation_type,
      'user_id' => user_id,
      'timestamp' => timestamp.iso8601(3)
    )
  end

  private

  def set_timestamp
    self.timestamp ||= Time.current
  end

  def set_applied_default
    self.applied = false if applied.nil?
  end
end
