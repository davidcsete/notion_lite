class CreateOperations < ActiveRecord::Migration[8.0]
  def change
    create_table :operations do |t|
      t.references :note, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :operation_type, null: false
      t.integer :position, null: false
      t.text :content
      t.datetime :timestamp, null: false
      t.boolean :applied, default: false, null: false

      t.timestamps
    end

    add_index :operations, [:note_id, :timestamp]
    add_index :operations, [:note_id, :applied]
    add_index :operations, :operation_type
  end
end
