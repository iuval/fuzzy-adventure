module CrystalClash
  module Models
    class Game
      include Mongoid::Document
      field :id
      field :turn, type: Integer, default: 1
      field :move_count_current_turn, type: Integer, default: 0
      field :ended, type: Boolean, default: false
      field :player_1_ended_game, type: Boolean, default: false
      field :player_2_ended_game, type: Boolean, default: false
      field :player_1_surrender, type: Boolean, default: false
      field :player_2_surrender, type: Boolean, default: false

      has_and_belongs_to_many :players

      embeds_many :moves

      index({ id: 1 }, { unique: true, name: "id_index" })
    end
  end
end
