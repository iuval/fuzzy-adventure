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
  field :email, type: String
  field :name, type: String
  field :random_enable, type: Boolean

  has_and_belongs_to_many :games
  has_one :invites, class_name: 'Invite', inverse_of: :host
  has_one :invited, class_name: 'Invite', inverse_of: :invited

  validates :email, uniqueness: true, length: { maximum: 30 }
  validates :name, length: { maximum: 30 }
end

class Game
  include Mongoid::Document
  field :id
  field :turn, type: Integer, default: 0
  field :move_count_current_turn, type: Integer, default: 0

  has_and_belongs_to_many :players

  embeds_many :moves

  index({ id: 1 }, { unique: true, name: "id_index" })
end

class Move
  include Mongoid::Document
  field :id
  embedded_in :game
  belongs_to :player
  field :turn
  field :data

  index({ id: 1 }, { unique: true, name: "id_index" })
end

class Invite
  include Mongoid::Document
  belongs_to :host, class_name: 'Player', inverse_of: :invites
  belongs_to :invited, class_name: 'Player', inverse_of: :invited
end

get '/' do
  @players = Player.all
  @games = Game.all
  erb :index
end

get '/delete_all_games' do
  Game.delete_all
end 

get '/delete_all_players' do
  Player.delete_all
end 

post '/sign_in' do
  return error( "Don't be leaving empty params..." ) if params["email"].nil?

  begin
    if Player.where( email: params["email"] ).count > 0
      error("email already in use")
    else  
      player = Player.create!( email: params["email"], name: params["user"] )
      
      success(id: player._id)
    end
  rescue Mongoid::Errors::MongoidError => e
    error e.message
  end
end

post '/log_in' do
  return error( "Don't be leaving empty params..." ) if params["email"].nil?

  begin
    player = find_player(params)
    if player
      success(id: player.id)
    end
  rescue Mongoid::Errors::MongoidError => e
    error e.message
  end
end

post '/enable_random' do
  return error( "Don't be leaving empty params..." ) if params["id"].nil?

  begin
    player = Player.find(params["id"])
    if player
      random_player = Player.where(random_enable: true, :id.ne => player.id).sample

      if random_player
        game = Game.create!
        game.players << player
        game.players << random_player
        game.save

        random_player.random_enable = false
        random_player.save
      else
        player.random_enable = true
        player.save
      end

      success ""
    else
      error 'invalid id'
    end
  rescue Mongoid::Errors::MongoidError => e
    error e.message
  end
end

post '/disable_random' do
  return error( "Don't be leaving empty params..." ) if params["id"].nil?

  begin
    player = Player.find( params["id"] )
    if player
      player.random_enable = false
      player.save
    else
      error "invalid id"
    end
    success ""
  rescue Mongoid::Errors::MongoidError => e
    error e.message
  end
end

get '/list_games/p/:id' do
  return error( "Don't be leaving empty params..." ) if params["id"].nil?

  begin
    player = Player.find( params["id"] )
    if player
      games = []
      player.games.each do |game|
        name = game.players[0] == player ? game.players[1].email : game.players[0].email
        state = game.moves.where( player: player, turn: game.turn ).count == 0 ? 'play' : 'wait'

        games << { game_id: game.id, name: name, turn: game.turn, state: state }
      end
      success(games)
    else
      error "invalid id"
    end
  rescue Mongoid::Errors::MongoidError => e
    error e.message
  end
end

get '/game_turn/p/:player_id/g/:game_id' do
  return error( "Don't be leaving empty params..." ) if params["player_id"].nil? or  
                                                        params["game_id"].nil?

  player = Player.find( params["player_id"] )
  if player 
    game = player.games.find( params["game_id"] )
    if game
      turn = game.moves.where( :player.ne => player,turn: game.turn-1 ).first
      if turn
        success(turn.data)
      else
        success('none')
      end
    else
      error "invalid player id"
    end
  else
    error "invalid player id"
  end
end

post '/game_turn' do
  return error( "Don't be leaving empty params..." ) if params["player_id"].nil? or  
                                                        params["game_id"].nil? or 
                                                        params["data"].nil?
  begin
    player = Player.find( params["player_id"] )
    if player 
      game = player.games.find( params["game_id"] )
      if game
        move = game.moves.create!
        move.player = player
        move.turn = game.turn
        move.data = params['data']
        move.save

        if game.moves.where( turn: game.turn ).count == 2
          game.turn += 1
          game.save
        end

        success('')
      else
        error "invalid player id"
      end
    else
      error "invalid player id"
    end
  rescue Mongoid::Errors::MongoidError => e
    error e.message
  end
end

#helper
def error(msg)
  { value: "error", data: { message: msg } }.to_json
end

def success(data)
  { value: "ok", data: data }.to_json
end

def find_player(params)
  players = Player.where(email: params["email"])
  if players.count > 0
    players.first
  else
    error "invalid email"
    nil
  end
end
