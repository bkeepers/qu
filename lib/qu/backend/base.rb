require 'json'

module Qu
  module Backend
    class Base
      include Logger
      attr_accessor :connection

      def self.encode(data)
        Qu.dump_json(data)
      end

      def self.decode(data)
        Qu.load_json(data)
      end

      private

      def encode(data)
        self.class.encode(data)
      end

      def decode(data)
        self.class.decode(data)
      end
    end
  end
end
