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
      %W(INT TERM).each do |sig|
        trap(sig) do
          logger.info "Worker #{id} received #{sig}, shutting down"
          stop
        end
      end
    end

    def work
      logger.debug "Worker #{id} waiting for next job"
      job = nil
      queues.each { |queue_name|
        if job = Qu.pop(queue_name)
          break
        end
      }
      perform(job)
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
      logger.debug "Worker #{id} done"
      @running = false
    end

    def stop
      @running = false

      # If the backend is blocked waiting for a new job, this will
      # break them out.
      raise Stop unless @performing

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
      @hostname ||= `hostname`.strip
    end

    private

    def perform(job)
      logger.debug "Worker #{id} popped job #{job}"
      begin
        @performing = true
        job.perform
      ensure
        @performing = false
      end
      logger.debug "Worker #{id} complete job #{job}"
    end
  end
end
