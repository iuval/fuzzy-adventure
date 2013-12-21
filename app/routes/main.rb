module CrystalClash
  class App
    get '/' do
      @players = CrystalClash::Models::Player.paginate(page: params[:page])
      erb :index
    end

    get '/random_name' do
      respond_success CrystalClash::Helpers::Players.random_name
    end

    get '/list_games/p/:id' do
      return respond_error("Don't be leaving empty params...") if params["id"].nil?

      player = CrystalClash::Models::Player.where(id: params["id"]).first
      if player
        games = []
        player.games.each do |game|
          unless game.ended
            if game.players[0] == player && !game.player_1_ended_game
              name = game.players[1].name
              emblem = game.players[1].emblem
              victories = game.players[1].victory_total
              state = game.moves.where(player: player, turn: game.turn).count == 0 ? 'play' : 'wait'
            elsif !game.player_2_ended_game
              name = game.players[0].name
              emblem = game.players[0].emblem
              victories = game.players[0].victory_total
              state = game.moves.where(player: player, turn: game.turn).count == 0 ? 'play' : 'wait'
            end
            games << { game_id: game.id,
                       name: name,
                       victories: victories,
                       turn: game.turn,
                       state: state,
                       emblem: emblem }
          end
        end
        respond_success(games)
      else
        respond_error "invalid id"
      end
    end

    get '/game_turn/p/:player_id/g/:game_id' do
      return respond_error("Don't be leaving empty params...") if params["player_id"].nil? or  params["game_id"].nil?

      player = CrystalClash::Models::Player.where(id: params["player_id"]).first
      if player
        game = player.games.where(id: params["game_id"]).first
        if game
          if game.players[0] == player
            turn1 = game.moves.where(player: player, turn: game.turn-1).first
            turn2 = game.moves.where(:player.ne => player, turn: game.turn-1).first
            player_num = 1
          else
            turn1 = game.moves.where(:player.ne => player, turn: game.turn-1).first
            turn2 = game.moves.where(player: player, turn: game.turn-1).first
            player_num = 2
          end
          if turn1 && turn2
            data = { game_id: game.id, turn: game.turn, player: player_num, data1: turn1.data, data2: turn2.data }
          else
            data = { game_id: game.id, turn: game.turn, player: player_num, data: 'none' }
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
      return respond_error("Don't be leaving empty params...") if params["player_id"].nil? or
      params["game_id"].nil? or
      params["data"].nil?

      player = CrystalClash::Models::Player.where(id: params["player_id"]).first
      if player
        game = player.games.where(id: params["game_id"]).first
        if game
          move = game.moves.create!
          move.player = player
          move.turn = game.turn
          move.data = params['data']
          move.save

          unless params["result"].nil?
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

          if game.player_1_ended_game && game.player_2_ended_game
            game.ended = true
          else
            if game.moves.where(turn: game.turn).count == 2
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
    end
  end
end
