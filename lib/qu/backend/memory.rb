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
        @messages = {}
        @pending = {}
        @connection = @messages
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        queue_for(payload.queue) do |queue|
          queue.push(payload.id)
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

      def pop(queue_name = 'default')
        queue_for(queue_name) do |queue|
          unless queue.empty?
            begin
              if id = queue.pop(true) # nonblocking pop
                payload = Payload.new(load(@messages[id]))
                @pending[id] = payload
                payload
              end
            rescue ThreadError => e
              unless e.message =~ /queue empty/
                raise e
              end
            end
          end
        end
      end

      def size(queue = 'default')
        queue_for(queue).size
      end

      def clear(queue_name = 'default')
        queue_for(queue_name) { |queue| queue.clear }
      end

      private

      def queue_for(queue)
        if block_given?
          synchronize { yield(@queues[queue] ||= Queue.new) }
        else
          synchronize { @queues[queue] ||= Queue.new }
        end
      end
    end
  end
end
