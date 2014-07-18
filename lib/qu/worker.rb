require 'socket'
require 'qu/util/signal_handler'

module Qu
  class Worker
    include Logger

    SIGNALS = [:INT, :TERM]

    attr_accessor :queues

    # Internal: Raised when signal received, no job is being performed, and
    # graceful shutdown is disabled.
    class Abort < StandardError
    end

    # Internal: Raised when signal received and no job is being performed.
    class Stop < StandardError
    end

    def initialize(*queues)
      @queues = queues.flatten.map { |q| q.to_s.strip }
      raise("Please provide one or more queues to work on.") if @queues.empty?
      @running = false
      @performing = false
    end

    def id
      @id ||= "#{hostname}:#{pid}:#{queues.join(',')}"
    end

    def work
      did_work = false

      unless Qu.runner.full?
        queues.each do |queue_name|
          if payload = Qu.pop(queue_name)
            begin
              @performing = true
              Qu.runner.run(self, payload)
            ensure
              did_work = true
              @performing = false
              break
            end
          end
        end
      end

      did_work
    end

    def start
      return if running?
      @running = true

      logger.warn "Worker #{id} starting"
      register_signal_handlers

      loop do
        unless running?
          break
        end

        unless work
          sleep Qu.interval
        end
      end
    rescue => e
      logger.error("Failed run loop #{e.message}\n#{e.backtrace.join("\n")}")
      raise
    ensure
      stop
    end

    def stop
      @running = false
      Qu.runner.stop

      if performing?
        raise Abort unless Qu.graceful_shutdown
      else
        raise Stop
      end
    end

    def performing?
      @performing
    end

    def running?
      @running
    end

    private

    def pid
      @pid ||= Process.pid
    end

    def hostname
      @hostname ||= Socket.gethostname
    end

    def register_signal_handlers
      logger.debug "Worker #{id} registering traps for INT and TERM signals"
      Qu::Util::SignalHandler.trap( *SIGNALS ) do |signal|
        logger.info("Worker #{id} received #{signal}, stopping")
        stop
      end
    end
  end
end
