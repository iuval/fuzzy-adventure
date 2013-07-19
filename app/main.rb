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
  field :ip, type: String
  field :email, type: String
  field :name, type: String
  field :random_enable, type: Boolean

  has_many :games
  has_one :invites

  validates :email, uniqueness: true, length: { maximum: 30 }
  validates :name, length: { maximum: 30 }

  index({ id: 1 }, { unique: true, name: "id_index" })
end

class Game
  include Mongoid::Document
  field :id
  field :turn, type: Integer

  belongs_to :player, :as => :player1
  belongs_to :player, :as => :player2

  embeds_many :moves

  index({ id: 1 }, { unique: true, name: "id_index" })
end

class Move
  include Mongoid::Document
  field :id
  embedded_in :game
  belongs_to :player
  field :turn

  index({ id: 1 }, { unique: true, name: "id_index" })
end

class Invite
  include Mongoid::Document
  belongs_to :player, :as => :host
  belongs_to :player, :as => :invited
end

get '/' do
  @players = Player.all
  erb :index
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

get '/log_in' do
  return error("Don't be leaving empty params...") if params["ip"].nil? || params["email"].nil?

  begin
    player = Player.where(email: params["email"])
    
    success(id: player.id)
  rescue Mongoid::Errors::MongoidError => e
    error(e.message)
  end
end

post '/enable_random' do
  return error("Don't be leaving empty params...") if params["id"].nil?

  begin
    player = Player.find(params["id"])
    
    player.update(enable_random: true)

    random_player = Player.where(enable_random: true, :id.ne => player.id).sample

    if random_player
      Game.create!(player1: player, player2: random_player)
    end

    success()
  rescue Mongoid::Errors::MongoidError => e
    error(e.message)
  end
end

post '/disable_random' do
  return error("Don't be leaving empty params...") if params["id"].nil?

  begin
    player = Player.find(params["id"])
    
    player.update(enable_random: false)

    success()
  rescue Mongoid::Errors::MongoidError => e
    error(e.message)
  end
end

get '/list_games' do
  return error("Don't be leaving empty params...") if params["id"].nil?

  begin
    player = Player.find(params["id"])
    if player
      games = {}
      player.games.each do |game|
        name = game.player1 == player ? game.player2 : game.player1
        state = game.moves.exists(player: player, turn: game.turn) ? 'wait' : 'play'

        games << { game_id: game.id, name: name, turn: game.turn. state: state }
      end
      success(games)
    end
  rescue Mongoid::Errors::MongoidError => e
    error(e.message)
  end
end

#helper
def error(msg)
  { value: "error", data: { message: msg } }
end

def success(data)
  { value: "ok", data: data }
end

