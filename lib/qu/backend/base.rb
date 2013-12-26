require 'json'

module Qu
  module Backend
    class Base
      include Logger
      attr_accessor :connection

      private

      def encode(data)
        JSON.dump(data) if data
      end

      def decode(data)
        JSON.load(data) if data
      end
    end
  end
end
