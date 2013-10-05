module CrystalClash
  module Models
    class Move
      include Mongoid::Document
      field :id
      embedded_in :game
      belongs_to :player
      field :turn
      field :data

      index({ id: 1 }, { unique: true, name: "id_index" })
    end
  end
end
