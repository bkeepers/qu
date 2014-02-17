require 'json'

module Qu
  module Backend
    class Base
      include Logger
      attr_accessor :connection

      def self.dump(data)
        Qu.dump_json(data)
      end

      def self.load(data)
        Qu.load_json(data)
      end

      # Public: Override in subclass.
      def reconnect
      end

      private

      def dump(data)
        self.class.dump(data)
      end

      def load(data)
        self.class.load(data)
      end
    end
  end
end
