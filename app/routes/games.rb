module CrystalClash
  class App
    get '/games' do
      @games = CrystalClash::Models::Game.paginate(page: params[:page])
      erb :games
    end

    get '/games/:game_id' do
      @game = CrystalClash::Models::Game.find( params["game_id"] )
      @moves = @game.moves.paginate(page: params[:page])
      erb :game
    end
  end
end
