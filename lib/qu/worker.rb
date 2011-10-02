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
      prune_dead_workers
      handle_signals
      Qu.backend.register_worker(self)
      loop { work }
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
    
    private
      def prune_dead_workers
        all_workers = Qu.backend.workers
        local_workers_pids = worker_pids unless all_workers.empty?
        
        all_workers.each do |worker|
          next if worker.hostname != self.hostname
          next if local_workers_pids.include?(worker.pid)
          logger.info "Pruning dead worker: #{worker.id}"
          Qu.backend.unregister_worker(worker)
        end
      end
      
      def worker_pids
        `ps -A -o pid,command | grep '[q]u:work'`.split("\n").map do |line|
            line.split(' ')[0]
        end
      end
  end
end
