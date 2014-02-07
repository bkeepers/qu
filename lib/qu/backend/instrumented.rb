require 'forwardable'
require 'qu/backend/wrapper'

module Qu
  module Backend
    # Internal: Backend that wraps all backends with instrumentation.
    class Instrumented < Base
      include Wrapper
      include Qu::Instrumenter

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

      def fail(payload)
        instrument("fail.#{InstrumentationNamespace}") { |ipayload|
          ipayload[:payload] = payload
          @backend.fail(payload)
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
