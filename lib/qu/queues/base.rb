require 'json'

module Qu
  module Queues
    class Base
      # Public: The name the queue was registered as.
      attr_accessor :name

      # Public: Override in subclass.
      def push(payload)
        payload.id = SecureRandom.uuid
        payload.perform
      end

      # Public: Override in subclass.
      def complete(payload)
      end

      # Public: Override in subclass.
      def abort(payload)
      end

      # Public: Override in subclass.
      def fail(payload)
      end

      # Public: Override in subclass.
      def pop
      end

      # Public: Override in subclass.
      def size
        0
      end

      # Public: Override in subclass.
      def clear
      end

      # Public: Override in subclass.
      def reconnect
      end

      private

      def dump(data)
        Qu.dump_json(data)
      end

      def load(data)
        Qu.load_json(data)
      end

      def logger
        Qu.logger
      end
    end
  end
end
