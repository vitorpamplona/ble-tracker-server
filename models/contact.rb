class Contact < ActiveRecord::Base
  # t.string :uploader
  # t.string :contact
  # t.datetime :start_time
  # t.datetime :end_time
  # t.integer :rssi
  # t.string :ip_address 
  # t.string :employee_id
  scope :uploader, ->(uploader) { where(uploader: uploader) }
  scope :contact, ->(contact) { where(contact: contact) }
end

# With IP Address. 
#curl -i -X POST -H "Content-Type: application/json" \
#       -d'{"uploader":"upSerial", "contact":"conSerial", "date":"2020-03-19T07:22Z", "rssi":-27, "ip_address":"291.222.222.1", "employee_id":"2233"}' \
#       http://localhost:4567/api/v1/contacts