require 'qu/util/signal_handler'
require 'qu/util/procline'

module Qu
  module Util
    FailedToForkError = Class.new(StandardError)
    ExitFailureError = Class.new(StandardError)

    class ProcessWrapper
      attr_reader :pid, :payload, :worker, :kill_timeout

      def initialize(process_collection, worker, payload, kill_timeout = 5)
        @process_collection = process_collection
        @worker = worker
        @payload = payload
        @kill_timeout = kill_timeout
      end

      def fork
        payload.job.run_before_hook(:fork)
        parent_pid = Process.pid
        @pid = Kernel.fork do
          begin
            $stdout.sync = true
            $stderr.sync = true
            Qu::Util::Procline.set("fork of #{parent_pid} working on #{payload.id} from #{payload.queue.name}")
            worker.queues.each(&:reconnect)
            SignalHandler.clear(*Qu::Worker::SIGNALS)
            payload.job.run_after_hook(:fork)
            payload.perform
          ensure
            exit!
          end
        end

        if @pid
          setup_wait_watcher
        else
          raise FailedToForkError.new("Could not fork process")
        end

        @pid
      end

      def setup_wait_watcher
        @process_collection[pid] = self
        Thread.new do
          begin
            Process.waitpid(pid) rescue SystemCallError
            payload.fail(ExitFailureError.new($?.to_s)) if $?.signaled?
          rescue => e
            logger.error("Failed waiting for process #{e.message}\n#{e.backtrace.join("\n")}")
          ensure
            @process_collection.delete(pid)
          end
        end
      end

      def stop
        return unless pid

        if Process.waitpid(pid, Process::WNOHANG)
          logger.info "Child #{pid} already quit."
          return
        end

        signal_child("TERM")
        signal_child("KILL") unless quit_gracefully?
      rescue SystemCallError
        logger.info "Child #{pid} already quit and reaped."
      ensure
        @process_collection.delete(pid)
      end

      def signal_child(signal)
        logger.info "Sending #{signal} signal to child #{pid}"
        Process.kill(signal, pid)
      end

      def quit_gracefully?
        if Qu.graceful_shutdown
          self.kill_timeout.times do
            sleep(1)
            return true if Process.waitpid(pid, Process::WNOHANG)
          end
        end
        return false
      end

      def logger
        Qu.logger
      end
    end
  end
end
