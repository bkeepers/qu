require 'forwardable'

module Qu
  module Queues
    # Internal: Queues that wraps all queues with instrumentation.
    class Instrumented < Base
      extend Forwardable
      include Qu::Instrumenter

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
        instrument("push.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @queue.push(payload)
        }
      end

      def complete(payload)
        instrument("complete.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @queue.complete(payload)
        }
      end

      def abort(payload)
        instrument("abort.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @queue.abort(payload)
        }
      end

      def fail(payload)
        instrument("fail.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @queue.fail(payload)
        }
      end

      def pop
        instrument("pop.#{InstrumentationNamespace}") { |ipayload|
          payload = @queue.pop
          ipayload[:payload] = payload
          ipayload[:queue_name] = @queue.name
          payload
        }
      end

      def size
        instrument("size.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:queue_name] = @queue.name
          @queue.size
        }
      end

      def clear
        instrument("clear.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:queue_name] = @queue.name
          @queue.clear
        }
      end
    end
  end
end
