require 'forwardable'

module Qu
  module Queues
    # Internal: Queues that wraps all queues with instrumentation.
    class Instrumented < Base
      extend Forwardable

      def self.wrap(queue)
        if queue.nil?
          queue
        else
          new(queue)
        end
      end

      def_delegators :@queue, :connection, :connection=, :reconnect, :name

      def initialize(queue)
        @queue = queue
      end

      def push(payload)
        Qu.instrument("push") { |ipayload|
          ipayload[:payload] = payload
          @queue.push(payload)
        }
      end

      def complete(payload)
        Qu.instrument("complete") { |ipayload|
          ipayload[:payload] = payload
          @queue.complete(payload)
        }
      end

      def abort(payload)
        Qu.instrument("abort") { |ipayload|
          ipayload[:payload] = payload
          @queue.abort(payload)
        }
      end

      def fail(payload)
        Qu.instrument("fail") { |ipayload|
          ipayload[:payload] = payload
          @queue.fail(payload)
        }
      end

      def pop
        Qu.instrument("pop") { |ipayload|
          payload = @queue.pop
          ipayload[:payload] = payload
          ipayload[:queue_name] = @queue.name
          payload
        }
      end

      def size
        Qu.instrument("size") { |ipayload|
          ipayload[:queue_name] = @queue.name
          @queue.size
        }
      end

      def clear
        Qu.instrument("clear") { |ipayload|
          ipayload[:queue_name] = @queue.name
          @queue.clear
        }
      end
    end
  end
end
