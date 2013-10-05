module CrystalClash
  module Helpers
    module Routes
        #helper
      def respond_error(msg)
        { value: "error", message: msg }.to_json
      end

      def respond_success(data)
        { value: "ok", data: data }.to_json
      end
    end
  end
end

CrystalClash::App.helpers CrystalClash::Helpers::Routes
