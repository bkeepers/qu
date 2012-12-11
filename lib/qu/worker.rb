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
          @running = false
          logger.info "Worker #{id} received #{sig}, shutting down"
          if @performing && Qu.graceful_shutdown
            stop
          else
            raise Abort
          end
        end
      end
    end

    def work_off
      logger.debug "Worker #{id} working of all jobs"
      while job = Qu.reserve(self, :block => false)
        logger.debug "Worker #{id} reserved job #{job}"
        begin
          @performing = true
          job.perform
        ensure
          @performing = false
        end
        logger.debug "Worker #{id} completed job #{job}"
      end
    end

    def work
      logger.debug "Worker #{id} waiting for next job"
      job = Qu.reserve(self)
      logger.debug "Worker #{id} reserved job #{job}"
      begin
        @performing = true
        job.perform
      ensure
        @performing = false
      end
      logger.debug "Worker #{id} completed job #{job}"
    end

    def start
      return if @running
      @running = true
      
      logger.warn "Worker #{id} starting"
      handle_signals
      Qu.backend.register_worker(self)
      loop do
        break unless @running
        work
      end
    ensure
      Qu.backend.unregister_worker(self)
      logger.debug "Worker #{id} done"
      @running = false
    end
    
    def stop
      @running = false
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
