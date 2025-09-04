class ChangeOperationTypeToIntegerInOperations < ActiveRecord::Migration[8.0]
  def up
    # Convert existing string values to integers
    execute <<-SQL
      UPDATE operations SET operation_type = 
        CASE 
          WHEN operation_type = 'insert' THEN '0'
          WHEN operation_type = 'delete' THEN '1'
          WHEN operation_type = 'retain' THEN '2'
          ELSE operation_type
        END
    SQL
    
    # Change column type to integer
    change_column :operations, :operation_type, :integer, using: 'operation_type::integer'
  end

  def down
    # Change back to string
    change_column :operations, :operation_type, :string
    
    # Convert integer values back to strings
    execute <<-SQL
      UPDATE operations SET operation_type = 
        CASE 
          WHEN operation_type = '0' THEN 'insert'
          WHEN operation_type = '1' THEN 'delete'
          WHEN operation_type = '2' THEN 'retain'
          ELSE operation_type
        END
    SQL
  end
end
