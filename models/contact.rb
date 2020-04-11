class Contact < ActiveRecord::Base
# t.string :uploader
# t.string :contact
# t.datetime :start_time
# t.datetime :end_time
# t.integer :rssi
  scope :uploader, ->(uploader) { where(uploader: uploader) }
  scope :contact, ->(contact) { where(contact: contact) }
end

# curl -i -X POST -H "Content-Type: application/json" \
#       -d'{"uploader":"upSerial", "contact":"conSerial", "start_time":"2020-03-19T07:22Z", "end_time":"2020-03-19T07:25Z", "rssi":-27}' \
#       http://localhost:4567/api/v1/contacts
#