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

      def_delegators :@queue, :connection, :connection=, :reconnect

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

      def pop(queue_name)
        instrument("pop.#{InstrumentationNamespace}") { |ipayload|
          result = @queue.pop(queue_name)
          ipayload[:payload] = result
          ipayload[:queue_name] = queue_name
          result
        }
      end

      def size(queue_name)
        instrument("size.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:queue_name] = queue_name
          @queue.size(queue_name)
        }
      end

      def clear(queue_name)
        instrument("clear.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:queue_name] = queue_name
          @queue.clear(queue_name)
        }
      end
    end
  end
end
