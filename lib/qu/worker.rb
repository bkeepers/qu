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
    end

    def work_off
      logger.debug "Worker #{id} working of all jobs"
      while job = Qu.reserve(self, :block => false)
        logger.debug "Worker #{id} reserved job #{job}"
        @job = job
        job.perform
        @job = nil
        logger.debug "Worker #{id} completed job #{job}"
      end
    end

    def work
      logger.debug "Worker #{id} waiting for next job"
      job = Qu.reserve(self)
      logger.debug "Worker #{id} reserved job #{job}"
      @job = job
      job.perform
      @job = nil
      logger.debug "Worker #{id} completed job #{job}"
    end

    def start
      logger.warn "Worker #{id} starting"
      handle_signals
      Qu.backend.reenqueue_zombie_jobs @queues if Qu.backend.respond_to?(:reenqueue_zombie_jobs)
      Qu.backend.register_worker(self)
      loop { work }
    rescue Abort => e
      # Ok, we'll shut down, but give us a sec
      @job.abort!
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

    def alive?
      `ps  -p#{@pid}`.lines.count > 1
    end

    def hostname
      @hostname ||= `hostname`.strip
    end
  end
end
