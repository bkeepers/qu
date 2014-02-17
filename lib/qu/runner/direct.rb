require 'qu/runner/base'

module Qu
  module Runner
    class Direct < Base
      def run(worker, payload)
        @full = true
        payload.perform
      ensure
        @full = false
      end

      def full?
        @full
      end
    end
  end
end
