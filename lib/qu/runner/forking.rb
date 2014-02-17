require 'qu/runner/base'
require 'qu/util/signal_handler'
require 'qu/util/thread_safe_hash'
require 'qu/util/process_wrapper'

module Qu
  module Runner

    class Forking

      attr_reader :fork_limit, :forks

      def initialize( fork_limit = 1 )
        @fork_limit = fork_limit
        @forks = Qu::Util::ThreadSafeHash.new
      end

      def full?
        forks.size == fork_limit
      end

      def run(worker, payload)
        raise RunnerLimitReached.new("#{self.class.name} is already running #{fork_limit} jobs") if full?

        process = Qu::Util::ProcessWrapper.new( forks, worker, payload )
        process.fork
      end

      def stop
        forks.values.each do |process|
          process.stop
        end
      end

    end
  end
end