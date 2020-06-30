class AddEmployeeIdAndIpAddress < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :ip_address, :string
    add_column :contacts, :employee_id, :string
  end
end
