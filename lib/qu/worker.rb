module Qu
  class Worker
    include Logger

    attr_accessor :queues

    class Abort < Exception
    end

    def initialize(*queues)
      @queues = queues.flatten
      self.attributes = @queues.pop if @queues.last.is_a?(Hash)
      @queues << 'default' if @queues.empty?
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
          raise Abort
        end
      end
      logger.debug "Worker #{id} registering traps for USR2 for graceful quit"
      trap("QUIT") do
        logger.info "Worker #{id} received #{sig}, graceful shutting down"
        Qu.backend.unregister_worker(self)
        @shutdown = true
      end
    end

    def shutdown?
      !!@shutdown
    end

    def work_off
      logger.debug "Worker #{id} working of all jobs"
      while job = Qu.reserve(self, :block => false)
        logger.debug "Worker #{id} reserved job #{job}"
        job.perform
        logger.debug "Worker #{id} completed job #{job}"
      end
    end

    def work
      logger.debug "Worker #{id} waiting for next job"
      job = Qu.reserve(self)
      logger.debug "Worker #{id} reserved job #{job}"
      job.perform
      logger.debug "Worker #{id} completed job #{job}"
    end

    def start
      logger.warn "Worker #{id} starting"
      handle_signals
      Qu.backend.register_worker(self)
      loop do
        break if shutdown?
        work
      end
    rescue Abort => e
      # Ok, we'll shut down, but give us a sec
    ensure
      Qu.backend.unregister_worker(self)
      logger.debug "Worker #{id} done"
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
  end
end
