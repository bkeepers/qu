require 'forwardable'
require 'securerandom'

module Qu
  module Backend
    class Memory < Base
      extend Forwardable

      def_delegator :@monitor, :synchronize

      def initialize
        @monitor = Monitor.new
        @queues = {}
        @pending = {}
      end

      def push(payload)
        synchronize do
          payload.id = SecureRandom.uuid
          queue_for(payload.queue) << payload
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

      def pop(queue = 'default')
        synchronize do
          queue_for(queue).shift
        end
      end

      def size(queue = 'default')
        queue_for(queue).size
      end

      def clear(queue = 'default')
        synchronize { queue_for(queue).clear }
      end

      private

      def queue_for(queue)
        synchronize { @queues[queue] ||= [] }
      end

    end
  end
end