require 'rubygems'
require 'sinatra'
require 'mongoid'

ENV['RACK_ENV'] ||= 'development'

configure do
  Mongoid.configure do |config|
    if ENV['RACK_ENV'] && ENV['RACK_ENV'] == 'production'
      config.sessions = { default: { uri: ENV['MONGOHQ_URL'] } }
    else
      config.sessions = { default: { uri: 'mongodb://localhost:27017/cristalclash' } }
    end
  end
end

class Player
  include Mongoid::Document
  field :ip
  field :email
end

get '/' do
  @players = Player.all.to_json
  erb :index
end

get '/random' do
  Player.all.sample.to_json
end

post '/connect' do
  return { message: "Don't be leaving empty params..." } if params["ip"].empty? || params["email"].empty?

  if Player.create(ip: params["ip"], email: params["email"])
    { message: "success" }
  else
    { message: "error" }
  end
end

post '/disconnect' do
  return { message: "Don't be leaving empty params..." } if params["ip"].empty? || params["email"].empty?

  player = Player.finde(ip: params["ip"], email: params["email"])

  if player.delete
    { message: "success" }
  else
    { message: "error" }
  end
end