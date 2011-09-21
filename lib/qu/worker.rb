module Qu
  class Worker
    attr_accessor :current_job

    def initialize(*queues)
      @queues = queues.flatten
      self.attributes = @queues.pop if @queues.last.is_a?(Hash)
    end

    def attributes=(attrs)
      attrs.each do |attr, value|
        self.instance_variable_set("@#{attr}", value)
      end
    end

    def attributes
      {'hostname' => hostname, 'pid' => pid, 'queues' => @queues}
    end

    def running?
      @running
    end

    def handle_signals
      %W(INT TRAP).each do |sig|
        trap(sig) do
          if running?
            stop
          else
            raise Interrupt
          end
        end
      end
    end

    def queues
      @queues.map {|q| q == '*' ? Qu.queues.sort : q }.flatten.uniq
    end

    def work_off
      while job = Qu.reserve(self, :block => false)
        job.perform
      end
    end

    def work
      self.current_job = Qu.reserve(self)
      self.current_job.perform
      self.current_job = nil
    end

    def start
      handle_signals
      Qu.backend.register_worker(self)
      @running = true
      work while running?
    end

    def stop
      @running = false
      Qu.backend.release(current_job) if current_job
      Qu.backend.unregister_worker(self)
    end

    def id
      "#{hostname}:#{pid}:#{@queues.join(',')}"
    end

    def pid
      @pid ||= Process.pid
    end

    def hostname
      @hostname ||= `hostname`.strip
    end
  end
end
