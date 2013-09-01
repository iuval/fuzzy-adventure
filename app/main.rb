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
  field :password, type: String
  field :name, type: String
  field :random_enable, type: Boolean, default: false
  field :victory_total, type: Integer, default: 0
  field :defeat_total, type: Integer, default: 0
  field :draw_total, type: Integer, default: 0

  has_and_belongs_to_many :games
  has_one :invites, class_name: 'Invite', inverse_of: :host
  has_one :invited, class_name: 'Invite', inverse_of: :invited

  validates :email, uniqueness: true, length: { maximum: 30 }
  validates :name, length: { maximum: 30 }
end

class Game
  include Mongoid::Document
  field :id
  field :turn, type: Integer, default: 1
  field :move_count_current_turn, type: Integer, default: 0
  field :ended, type: Boolean, default: false 
  field :player_1_ended_game, type: Boolean, default: false 
  field :player_2_ended_game, type: Boolean, default: false 

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

get '/games/:game_id' do
  @game = Game.find( params["game_id"] )
  erb :game
end

get '/delete_all_games' do
  Game.delete_all
end 

get '/delete_all_players' do
  Player.delete_all
end 

post '/sign_in' do
  return respond_error( "Don't be leaving empty params..." ) if params["email"].nil? || params["password"].nil?

  begin
    if Player.where( email: params["email"] ).count > 0
      respond_error "email already in use"
    else  
      player = Player.create!( email: params["email"], password: params["password"] )
      
      respond_success(id: player._id)
    end
  rescue Mongoid::Errors::MongoidError => e
    respond_error e.message
  end
end

post '/log_in' do
  return respond_error( "Don't be leaving empty params..." ) if params["email"].nil? || params["password"].nil?

  begin
    players = Player.where(email: params["email"], password: params["password"])
    if players.count > 0
      player = players.first
      respond_success(id: player.id)
    else
      respond_error "invalid email or password"
    end
  rescue Mongoid::Errors::MongoidError => e
    respond_error e.message
  end
end

post '/enable_random' do
  return respond_error( "Don't be leaving empty params..." ) if params["id"].nil?

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

      respond_success ""
    else
      respond_error 'invalid id'
    end
  rescue Mongoid::Errors::MongoidError => e
    respond_error e.message
  end
end

post '/disable_random' do
  return respond_error( "Don't be leaving empty params..." ) if params["id"].nil?

  begin
    player = Player.find( params["id"] )
    if player
      player.random_enable = false
      player.save
    else
      respond_error "invalid id"
    end
    respond_success ""
  rescue Mongoid::Errors::MongoidError => e
    respond_error e.message
  end
end

get '/list_games/p/:id' do
  return respond_error( "Don't be leaving empty params..." ) if params["id"].nil?

  begin
    player = Player.find( params["id"] )
    if player
      games = []
      player.games.each do |game|
        unless game.ended
          if game.players[0] == player && !game.player_1_ended_game
            name = game.players[1].email
            victories = game.players[1].victory_total
            state = game.moves.where( player: player, turn: game.turn ).count == 0 ? 'play' : 'wait'
            games << { game_id: game.id, name: name, victories: victories, turn: game.turn, state: state }
          elsif !game.player_2_ended_game
            name = game.players[0].email
            victories = game.players[0].victory_total
            state = game.moves.where( player: player, turn: game.turn ).count == 0 ? 'play' : 'wait'
            games << { game_id: game.id, name: name, victories: victories,turn: game.turn, state: state }
          end
        end
      end
      respond_success(games)
    else
      respond_error "invalid id"
    end
  rescue Mongoid::Errors::MongoidError => e
    respond_error e.message
  end
end

get '/game_turn/p/:player_id/g/:game_id' do
  return respond_error( "Don't be leaving empty params..." ) if params["player_id"].nil? or  params["game_id"].nil?

  player = Player.find( params["player_id"] )
  if player 
    game = player.games.find( params["game_id"] )
    if game
      if game.players[0] == player
        turn1 = game.moves.where( player: player, turn: game.turn-1 ).first
        turn2 = game.moves.where( :player.ne => player, turn: game.turn-1 ).first
        player_num = 1
      else
        turn1 = game.moves.where( :player.ne => player, turn: game.turn-1 ).first
        turn2 = game.moves.where( player: player, turn: game.turn-1 ).first
        player_num = 2
      end
      if turn1 && turn2
        data = { game_id: game.id, player: player_num, data1: turn1.data, data2: turn2.data }
      else
        data = { game_id: game.id, player: player_num, data: 'none' }
      end
      respond_success(data)
    else
      respond_error "invalid player id"
    end
  else
    respond_error "invalid player id"
  end
end

post '/game_turn' do
  return respond_error( "Don't be leaving empty params..." ) if params["player_id"].nil? or  
  params["game_id"].nil? or 
  params["data"].nil?
  begin
    player = Player.find( params["player_id"] )
    if player 
      game = player.games.find( params["game_id"] )
      if game
        if params["result"].nil?
          move = game.moves.create!
          move.player = player
          move.turn = game.turn
          move.data = params['data']
          move.save
        else
          if params["result"] == 'victory'
            player.victory_total += 1
            player.save
          elsif params["result"] == 'defeat'
            player.defeat_total += 1
            player.save
          elsif params["result"] == 'draw'
            player.draw_total += 1
            player.save
          end
          if game.players[0] == player
            game.player_1_ended_game = true;
          else
            game.player_2_ended_game = true;
          end
        end

        if game.moves.where( turn: game.turn ).count == 2
          if game.player_1_ended_game && game.player_2_ended_game
            game.ended = true
          else
            game.turn += 1
          end
        end
        game.save

        respond_success('')
      else
        respond_error "invalid player id"
      end
    else
      respond_error "invalid player id"
    end
  rescue Mongoid::Errors::MongoidError => e
    respond_error e.message
  end
end

#helper
def respond_error(msg)
  { value: "error", message: msg }.to_json
end

def respond_success(data)
  { value: "ok", data: data }.to_json
end
