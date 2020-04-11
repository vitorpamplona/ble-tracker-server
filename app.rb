# app.rb
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/namespace'

current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file }

get '/' do
  'Hello world!'
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
        halt 400, { message:'Invalid JSON' }.to_json
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
    contact = Contact.new(json_params)
    if contact.save
      contact.to_json
    else
      status 422
    end
  end
end
