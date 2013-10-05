module CrystalClash
  module Helpers
    module Players

      def self.init_adjs(adjs)
        @@adjs = cap adjs
      end

      def self.init_super_adjs(super_adjs)
        @@super_adjs = cap super_adjs
      end

      def self.init_objects(objects)
        @@objects = cap objects
      end

      def self.cap(string_list)
        string_list.map(&:capitalize)
      end

      def self.random_name
        @@super_adjs.sample + " " + @@adjs.sample + " " + @@objects.sample
      end
    end
  end
end

CrystalClash::App.helpers CrystalClash::Helpers::Players
