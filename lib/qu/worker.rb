require 'socket'

module Qu
  class Worker
    include Logger

    attr_accessor :queues

    class Abort < StandardError
    end

    class Stop < Exception
    end

    def initialize(*queues)
      @queues = queues.flatten
      self.attributes = @queues.pop if @queues.last.is_a?(Hash)
      @queues << 'default' if @queues.empty?
      @running = false
      @performing = false
    end

    def attributes=(attrs)
      attrs.each do |attr, value|
        self.instance_variable_set("@#{attr}", value)
      end
    end

    def attributes
      {'hostname' => hostname, 'pid' => pid, 'queues' => queues}
    end

    def handle_signals
      logger.debug "Worker #{id} registering traps for INT and TERM signals"
      trap(:INT)  { stop }
      trap(:TERM) { stop }
    end

    def work
      job = nil
      queues.each { |queue_name|
        job = Qu.pop(queue_name)

        break if job
      }

      if job
        begin
          @performing = true
          job.perform
        ensure
          @performing = false
        end
      end
    end

    def start
      return if @running
      @running = true

      logger.warn "Worker #{id} starting"
      handle_signals

      loop do
        break unless @running
        work
      end
    ensure
      logger.debug "Worker #{id} stopping"
      @running = false
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

    def id
      @id ||= "#{hostname}:#{pid}:#{queues.join(',')}"
    end

    def pid
      @pid ||= Process.pid
    end

    def hostname
      @hostname ||= Socket.gethostname
    end

    def performing?
      !!@performing
    end

    def running?
      !!@running
    end
  end
end
