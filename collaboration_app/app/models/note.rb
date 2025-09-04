class Note < ApplicationRecord
  belongs_to :owner, class_name: 'User'

  # Associations
  has_many :collaborations, dependent: :destroy
  has_many :collaborators, through: :collaborations, source: :user
  has_many :operations, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :content, presence: true
  validates :document_state, presence: true

  # Callbacks
  before_validation :initialize_content, on: :create
  before_validation :initialize_document_state, on: :create

  # Scopes
  scope :accessible_by, ->(user) { 
    joins("LEFT JOIN collaborations ON notes.id = collaborations.note_id")
    .where("notes.owner_id = ? OR collaborations.user_id = ?", user.id, user.id)
    .distinct
  }

  def user_role(user)
    return 'owner' if owner_id == user.id
    collaboration = collaborations.find_by(user: user)
    collaboration&.role || nil
  end

  def accessible_by?(user)
    owner_id == user.id || collaborations.exists?(user: user)
  end

  private

  def initialize_content
    if content.blank? || (content.is_a?(Hash) && content.empty?)
      self.content = { "type" => "doc", "content" => [] }
    end
  end

  def initialize_document_state
    if document_state.blank? || (document_state.is_a?(Hash) && document_state.empty?)
      self.document_state = { "version" => 0, "operations" => [] }
    end
  end
end
