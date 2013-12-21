module CrystalClash
  module Helpers
    module Players
      def self.init_kinds(kinds)
        @@kinds = kinds
      end

      def self.init_jobs(jobs)
        @@jobs = jobs
      end

      def self.random_name
        @@kinds.sample + " " + @@jobs.sample
      end
    end
  end
end

CrystalClash::App.helpers CrystalClash::Helpers::Players
