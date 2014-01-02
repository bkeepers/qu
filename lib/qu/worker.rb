require 'socket'

module Qu
  class Worker
    include Logger

    # Private: The states that the worker can be in.
    States = [:initialized, :running, :performing, :stopped]

    attr_accessor :queues

    class Abort < StandardError
    end

    class Stop < Exception
    end

    def initialize(*queues)
      @queues = queues.flatten
      self.attributes = @queues.pop if @queues.last.is_a?(Hash)
      @queues << 'default' if @queues.empty?
      transition_to :initialized
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
            transition_to :performing
            payload.perform
          ensure
            did_work = true
            transition_to :running
            break
          end
        end
      }

      did_work
    end

    def start
      return if running?
      transition_to :running

      logger.warn "Worker #{id} starting"
      handle_signals

      loop do
        break unless running?
        work
      end
    ensure
      stop
    end

    def stop
      transition_to :stopped

      # If the backend is blocked waiting for a new job, this will
      # break them out.
      raise Stop unless performing?

      # If the backend is still performing a job and this is not a graceful
      # shutdown, abort immediately.
      raise Abort unless Qu.graceful_shutdown
    end

    def performing?
      @state == :performing
    end

    def running?
      @state == :running || performing?
    end

    private

    def pid
      @pid ||= Process.pid
    end

    def hostname
      @hostname ||= Socket.gethostname
    end

    def transition_to(state)
      if States.include?(state)
        @state = state
      else
        raise "Invalid transition: #{state} not one of #{States.join(', ')}"
      end
    end

    def handle_signals
      logger.debug "Worker #{id} registering traps for INT and TERM signals"
      trap(:INT)  { stop }
      trap(:TERM) { stop }
    end
  end
end
