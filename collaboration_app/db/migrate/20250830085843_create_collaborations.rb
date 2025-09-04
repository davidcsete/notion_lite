class CreateCollaborations < ActiveRecord::Migration[8.0]
  def change
    create_table :collaborations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :note, null: false, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end

    add_index :collaborations, [:user_id, :note_id], unique: true
    add_index :collaborations, :role
  end
end
