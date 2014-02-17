module Qu
  module Runner
    RunnerLimitReached = Class.new(StandardError)

    class Base
      # Public: Override in subclass.
      def run(worker, payload)
        payload.perform
      end

      # Public: Override in subclass.
      def stop
      end

      # Public: Override in subclass.
      def full?
        false
      end
    end
  end
end
