class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :owned_notes, class_name: 'Note', foreign_key: 'owner_id', dependent: :destroy
  has_many :collaborations, dependent: :destroy
  has_many :notes, through: :collaborations
  has_many :operations, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  # Scopes
  scope :by_email, ->(email) { where(email: email) }

  def accessible_notes
    Note.joins("LEFT JOIN collaborations ON notes.id = collaborations.note_id")
        .where("notes.owner_id = ? OR collaborations.user_id = ?", id, id)
        .distinct
  end
end
