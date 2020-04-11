class CreateContactsTable < ActiveRecord::Migration[6.0]
  def change
    create_table :contacts do |t|
      t.string :uploader
      t.string :contact
      t.datetime :start_time
      t.datetime :end_time
      t.integer :rssi

      t.timestamps
    end
  end
end
