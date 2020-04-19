# app.rb
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/namespace'
require 'sinatra/reloader' if development?
require 'chartkick'

current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file }

get '/' do
  @timeline = []

  db = Contact.select(:uploader, :contact, :start_time, :end_time)
  db.each { |item|
    logger.info item
    @timeline.append(uploader: item.uploader, contact: item.contact, start: item.start_time, end: item.end_time)
  }
  erb :chart
end

namespace '/api/v1' do
  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
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

    [:uploader, :contact].each do |filter|
      contacts = contacts.send(filter, params[filter]) if params[filter]
    end

    contacts.to_json
  end

  post '/contacts' do
    params = json_params

    # Interface: { uploader:_uploader, contact: _contact, rssi:_rssi, date:_date };
    contact = Contact.where(['uploader = ? and contact = ? and start_time > ? and end_time < ?',
                             params['uploader'], params['contact'],
                             DateTime.parse(params['date']), DateTime.parse(params['date'])
    ]).first

    if contact 
      return contact.to_json
    end

    # Interface: { uploader:_uploader, contact: _contact, rssi:_rssi, date:_date };
    contact = Contact.where(['uploader = ? and contact = ? and end_time > ?',
                             params['uploader'], params['contact'],
                             DateTime.parse(params['date']) - 2.minute]).first

    if contact
      contact.end_time = params['date'] if contact.end_time < params['date'];
      contact.rssi = params['rssi'] if params['rssi'];
    else
      contact = Contact.new()
      contact.uploader = params['uploader']
      contact.contact = params['contact']
      contact.start_time = params['date']
      contact.end_time = params['date']
      contact.rssi = params['rssi']
    end

    if contact.save
      contact.to_json
    else
      status 422
    end
  end
end
