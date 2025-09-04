class ChangeRoleToIntegerInCollaborations < ActiveRecord::Migration[8.0]
  def up
    # Convert existing string values to integers
    execute <<-SQL
      UPDATE collaborations SET role = 
        CASE 
          WHEN role = 'editor' THEN '0'
          WHEN role = 'viewer' THEN '1'
          ELSE role
        END
    SQL
    
    # Change column type to integer
    change_column :collaborations, :role, :integer, using: 'role::integer'
  end

  def down
    # Change back to string
    change_column :collaborations, :role, :string
    
    # Convert integer values back to strings
    execute <<-SQL
      UPDATE collaborations SET role = 
        CASE 
          WHEN role = '0' THEN 'editor'
          WHEN role = '1' THEN 'viewer'
          ELSE role
        END
    SQL
  end
end
