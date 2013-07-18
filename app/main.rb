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
  field :id
  field :ip
  field :email
  field :name

  validates :email, uniqueness: true
  index({ id: 1 }, { unique: true, name: "id_index" })
end

get '/' do
  @players = Player.all
  erb :index
end

get '/random' do
  Player.all.sample
end

post '/sign_in' do
  return error("Don't be leaving empty params...") if params["ip"].nil? || params["email"].nil?

  begin
    player = Player.create!(ip: params["ip"], email: params["email"], name: params["user"])
    
    success(id: player.id)
  rescue Mongoid::Errors::MongoidError => e
    error(e.message)
  end
end

post '/log_in' do
  return error("Don't be leaving empty params...") if params["ip"].nil? || params["email"].nil?

  begin
    Player.create!(ip: params["ip"], email: params["email"], name: params["user"])
    
    success(data)
  rescue Mongoid::Errors::MongoidError => e
    error(e.message)
  end
end

post '/disconnect' do
  return { message: "Don't be leaving empty params..." } if params["ip"].empty? || params["email"].empty?

  player = Player.where(ip: params["ip"], email: params["email"])

  if player.delete
    { message: "success" }
  else
    { message: "error" }
  end
end

#helper
def error(msg)
  { value: "error", data: { message: msg } }
end

def success(data)
  { value: "ok", data: data }
end

