module Qu
  class Worker
    def initialize(*queues)
      @running = true
      @queues = queues.flatten
      handle_signals
    end

    def running?
      @running
    end

    def handle_signals
      %W(INT TRAP).each do |sig|
        trap(sig) do
          if running?
            @running = false
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
      job = Qu.reserve(self)
      job.perform
    end

    def start
      while running? do
        work
      end
    end
  end
end
