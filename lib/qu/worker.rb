require 'socket'

module Qu
  class Worker
    include Logger

    attr_accessor :queues

    # Internal: Raised when signal received, no job is being performed, and
    # graceful shutdown is disabled.
    class Abort < StandardError
    end

    # Internal: Raised when signal received and no job is being performed.
    class Stop < Exception
    end

    def initialize(*queues)
      @queues = queues.flatten
      self.attributes = @queues.pop if @queues.last.is_a?(Hash)
      @queues << 'default' if @queues.empty?
      @running = false
      @performing = false
    end

    def id
      @id ||= "#{hostname}:#{pid}:#{queues.join(',')}"
    end

    def attributes
      {'hostname' => hostname, 'pid' => pid, 'queues' => queues}
    end

    def attributes=(attrs)
      attrs.each do |attr, value|
        self.instance_variable_set("@#{attr}", value)
      end
    end

    def work
      did_work = false

      queues.each { |queue_name|
        if payload = Qu.pop(queue_name)
          begin
            @performing = true
            payload.perform
          ensure
            did_work = true
            @performing = false
            break
          end
        end
      }

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
    ensure
      stop
    end

    def stop
      @running = false

      # If the backend is blocked waiting for a new job, this will
      # break them out.
      raise Stop unless performing?

      # If the backend is still performing a job and this is not a graceful
      # shutdown, abort immediately.
      raise Abort unless Qu.graceful_shutdown
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
      trap(:INT)  { puts "Worker #{id} received INT, stopping"; stop }
      trap(:TERM) { puts "Worker #{id} received TERM, stopping"; stop }
    end
  end
end
