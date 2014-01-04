require 'forwardable'

module Qu
  module Backend
    # Internal: Backend that wraps all backends with instrumentation.
    class Instrumented < Base
      extend Forwardable
      include Qu::Instrumenter

      def self.wrap(backend)
        if backend.nil?
          backend
        else
          new(backend)
        end
      end

      def_delegators :@backend, :connection, :connection=

      def initialize(backend)
        @backend = backend
      end

      def push(payload)
        instrument("push.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @backend.push(payload)
        }
      end

      def complete(payload)
        instrument("complete.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @backend.complete(payload)
        }
      end

      def abort(payload)
        instrument("abort.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @backend.abort(payload)
        }
      end

      def pop(queue_name = 'default')
        instrument("pop.#{InstrumentationNamespace}") { |ipayload|
          result = @backend.pop(queue_name)
          ipayload[:payload] = result
          ipayload[:queue_name] = queue_name
          result
        }
      end

      def size(queue_name = 'default')
        instrument("size.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:queue_name] = queue_name
          @backend.size(queue_name)
        }
      end

      def clear(queue_name = 'default')
        instrument("clear.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:queue_name] = queue_name
          @backend.clear(queue_name)
        }
      end
    end
  end
end
