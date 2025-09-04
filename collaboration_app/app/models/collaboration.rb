class Collaboration < ApplicationRecord
  belongs_to :user
  belongs_to :note

  # Enums
  enum :role, { editor: 0, viewer: 1 }

  # Validations
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :user_id, uniqueness: { scope: :note_id, message: "User is already a collaborator on this note" }

  # Scopes
  scope :editors, -> { where(role: 'editor') }
  scope :viewers, -> { where(role: 'viewer') }
  scope :for_note, ->(note) { where(note: note) }
  scope :for_user, ->(user) { where(user: user) }

  def can_edit?
    editor?
  end

  def can_view?
    true # All collaborators can view
  end
end
