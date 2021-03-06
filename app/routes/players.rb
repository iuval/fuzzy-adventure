module CrystalClash
  class App
    post '/sign_in' do
      return respond_error("Don't be leaving empty params...") if params["email"].nil? || params["password"].nil? || params["name"].nil?
      params["name"] ||= CrystalClash::Helpers::Players.random_name
      if CrystalClash::Models::Player.where(email: params["email"]).count > 0
        respond_error 'email already in use'
      else
        player = CrystalClash::Models::Player.new(email: params["email"],
                                                  password: params["password"],
                                                  name: params["name"])
        if player.save
          respond_success({ id: player._id,
                            victory_total: player.victory_total,
                            defeat_total: player.defeat_total,
                            draw_total: player.draw_total,
                            emblem: player.emblem })
        else
          respond_error "Woah! Something went wrong, try again later."
        end
      end
    end

    post '/log_in' do
      return respond_error("Don't be leaving empty params...") if params["email"].nil? || params["password"].nil?

      player = CrystalClash::Models::Player.where(email: params["email"], password: params["password"]).first
      if player
        respond_success({ id: player._id,
                          name: player.name,
                          victory_total: player.victory_total,
                          defeat_total: player.defeat_total,
                          draw_total: player.draw_total,
                          emblem: player.emblem })
      else
        respond_error "invalid email or password"
      end
    end

    post '/enable_random' do
      return respond_error("Don't be leaving empty params...") if params["id"].nil?

      player = CrystalClash::Models::Player.where(id: params["id"]).first
      if player
        random_player = CrystalClash::Models::Player.where(random_enable: true,:id.ne => player.id).sample

        if random_player
          game = CrystalClash::Models::Game.create
          game.players << player
          game.players << random_player
          game.save

          random_player.random_enable = false
          random_player.save

          respond_success({ game_id:   game.id,
                            name:      random_player.name,
                            victories: random_player.victory_total,
                            turn:      '1',
                            state:     'play',
                            emblem:    random_player.emblem,
                            surrender: false })
        else
          player.random_enable = true
          player.save

          respond_success ''
        end
      else
        respond_error 'invalid id'
      end
    end

    post '/disable_random' do
      return respond_error("Don't be leaving empty params...") if params["id"].nil?

      player = CrystalClash::Models::Player.where(id: params["id"]).first
      if player
        player.random_enable = false
        player.save
        return respond_success ''
      else
        return respond_error "invalid id"
      end
    end

    post '/update_player' do
      return respond_error("Don't be leaving empty params...") if params["id"].nil?

      player = CrystalClash::Models::Player.where(id: params["id"]).first
      if player
        player.name = params[:name] unless params[:name].nil?   
        player.email = params[:email] unless params[:email].nil?
        player.email = params[:password] unless params[:password].nil?
        player.emblem = params[:emblem] unless params[:emblem].nil?   
        player.save

        respond_success ''
      else
        respond_error 'invalid id'
      end
    end
  end
end
