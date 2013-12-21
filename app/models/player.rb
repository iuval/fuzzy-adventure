module CrystalClash
  module Models
    class Player
      include Mongoid::Document
      field :email, type: String
      field :password, type: String
      field :name, type: String
      field :random_enable, type: Boolean, default: false
      field :victory_total, type: Integer, default: 0
      field :defeat_total, type: Integer, default: 0
      field :draw_total, type: Integer, default: 0
      field :emblem, type: Integer, default: 0

      has_and_belongs_to_many :games
      has_one :invites, class_name: 'CrystalClash::Models::Invite', inverse_of: :host
      has_one :invited, class_name: 'CrystalClash::Models::Invite', inverse_of: :invited

      validates :email, uniqueness: true, length: { maximum: 30 }
      validates :name, length: { maximum: 30 }

      default_scope order_by([:victory_total, :desc])
    end
  end
end