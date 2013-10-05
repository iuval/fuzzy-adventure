module CrystalClash
  module Models
    class Invite
      include Mongoid::Document
      belongs_to :host, class_name: 'CrystalClash::Models::Player', inverse_of: :invites
      belongs_to :invited, class_name: 'CrystalClash::Models::Player', inverse_of: :invited
    end
  end
end
