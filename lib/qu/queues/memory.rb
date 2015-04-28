require 'forwardable'
require 'securerandom'

module Qu
  module Queues
    class Memory < Base
      extend Forwardable

      def_delegator :@monitor, :synchronize

      def initialize
        @monitor = Monitor.new
        @queue = []
        @messages = {}
        @pending = {}
        @connection = @messages
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        with_queue do |queue|
          queue << payload.id
          @messages[payload.id] = dump(payload.attributes_for_push)
          payload
        end
      end

      def complete(payload)
        synchronize { @pending.delete(payload.id) }
      end

      def abort(payload)
        synchronize do
          @pending.delete(payload.id)
          push(payload)
        end
      end

      alias fail abort

      def pop
        with_queue do |queue|
          if id = queue.shift
            payload = Payload.new(load(@messages[id]))
            @pending[id] = payload
            payload
          end
        end
      end

      def size
        with_queue { |queue| queue.size }
      end

      def clear
        with_queue { |queue| queue.clear }
      end

      private

      def with_queue
        synchronize { yield(@queue) }
      end
    end
  end
end
