# app.rb
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/namespace'
require 'sinatra/reloader' if development?

current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file }

get '/' do
  @timeline = []

  db = Contact.select(:uploader, :contact, :start_time, :end_time)
              .order(:start_time, :contact)

  db.each { |item|
    @timeline.append(uploader: item.uploader, contact: item.contact,
                     start: item.start_time, end: item.end_time)
  }
  erb :chart
end

get '/terms' do
  'Terms and Conditions'
end

namespace '/api/v1' do
  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message: "Invalid JSON: #{request.body.read}" }.to_json
      end
    end
  end

  before do
    content_type 'application/json'
  end

  get '/contacts' do
    contacts = Contact.all

    %i[uploader contact].each do |filter|
      contacts = contacts.send(filter, params[filter]) if params[filter]
    end

    contacts.to_json
  end

  get '/health' do
    { version: '0.0.4' }.to_json
  end

  post '/contacts' do
    input = json_params
    list = input.is_a?(Array) ? input : [input]

    result = []
    list.each { |params|
      # { uploader:_uploader, contact: _contact, rssi:_rssi, date:_date };
      contact = Contact.where(['uploader = ? and contact = ? and start_time >= ? and end_time <= ?',
                               params['uploader'], params['contact'],
                               DateTime.parse(params['date']),
                               DateTime.parse(params['date'])
      ]).first

      if contact
        result.push(contact)
        next
      end

      # Interface: { uploader:_uploader, contact: _contact, rssi:_rssi, date:_date };
      contact = Contact.where(['uploader = ? and contact = ? and ? > start_time and ? < end_time',
                               params['uploader'], params['contact'],
                               DateTime.parse(params['date']) + 3.minute,
                               DateTime.parse(params['date']) - 3.minute]).first

      if contact
        contact.start_time = params['date'] if params['date'] < contact.start_time
        contact.end_time = params['date']   if params['date'] > contact.end_time
        contact.rssi = params['rssi'] if params['rssi']
      else
        contact = Contact.new
        contact.uploader = params['uploader']
        contact.contact = params['contact']
        contact.start_time = params['date']
        contact.end_time = params['date']
        contact.rssi = params['rssi']
        contact.ip_address = params['ip_address']
        contact.employee_id = params['employee_id']
      end

      if contact.save
        result.push(contact)
      end 
    }

    p "Processed #{list.length} inputs into #{result.length} outputs" 

    if !result.empty?
      if result.length == 1
        result[0].to_json
      else
        result.to_json
      end
    else
      status 422
    end
  end

  get '/check' do
    users = Contact.select(:contact).group(:contact)
    users.each { |user|
      users.each { |contact|
        contacts = Contact.where(uploader: user.contact, contact: contact.contact).order(:start_time)

        contacts.each_with_index do |contact, index|
          next if index.zero?

          prev_con = contacts[index - 1]

          if prev_con.end_time >= contact.start_time # goes into the next timeline
            if contact.end_time > prev_con.end_time 
              prev_con.end_time = contact.end_time
              prev_con.save!
              # contact.destroy! #make it in. Then delete. 
              puts "Up #{prev_con.start_time}, #{contact.start_time}, #{prev_con.end_time}, #{contact.end_time}"
            else
              contact.destroy!
              puts "In #{prev_con.start_time}, #{contact.start_time}, #{contact.end_time}, #{prev_con.end_time}"
            end
          end
        end
      }
    }
    users.to_json
  end

  get '/merge' do
    users = Contact.select(:contact).group(:contact)
    users.each { |user|
      users.each { |contact|
        contacts = Contact.where(uploader: user.contact, contact: contact.contact).order(:start_time)

        contacts.each_with_index do |contact, index|
          next if index.zero?

          prev_con = contacts[index - 1]

          if (contact.start_time - prev_con.end_time).to_f / 60 < 3
            if contact.end_time >= prev_con.end_time
              prev_con.end_time = contact.end_time
              prev_con.save!
              # contact.destroy!
              puts "Join #{prev_con.start_time}, #{prev_con.end_time}, #{contact.start_time}, #{contact.end_time} with #{(contact.start_time - prev_con.end_time).to_f / 60}"
            else
              puts ">?>?? #{prev_con.end_time} #{contact.end_time}"
            end
          end
        end
      }
    }
    users.to_json
  end
end
