class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.string :title, null: false
      t.jsonb :content, null: false, default: {}
      t.references :owner, null: false, foreign_key: { to_table: :users }, index: true
      t.jsonb :document_state, null: false, default: {}

      t.timestamps
    end

    add_index :notes, :content, using: :gin
    add_index :notes, :document_state, using: :gin
  end
end
