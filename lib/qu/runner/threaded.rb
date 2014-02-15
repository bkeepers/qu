module Qu
  module Runner
    class Threaded

      attr_reader :thread_count

      def initialize( options = {} )
        @thread_count = options[:threads] || 1
      end



    end
  end
end