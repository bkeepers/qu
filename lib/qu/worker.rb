module Qu
  class Worker
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
      %W(INT TERM).each do |sig|
        trap(sig) { raise Abort }
      end
    end

    def work_off
      while job = Qu.reserve(self, :block => false)
        job.perform
      end
    end

    def work
      job = Qu.reserve(self)
      job.perform
    end

    def start
      Qu.logger.info "Starting worker #{id}"
      handle_signals
      Qu.backend.register_worker(self)
      loop { work }
    rescue Abort => e
      # Ok, we'll shut down, but give us a sec
    ensure
      Qu.logger.info "Stopping worker #{id}"
      Qu.backend.unregister_worker(self)
    end

    def id
      "#{hostname}:#{pid}:#{queues.join(',')}"
    end

    def pid
      @pid ||= Process.pid
    end

    def hostname
      @hostname ||= `hostname`.strip
    end
  end
end
