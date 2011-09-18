module Qu
  class Worker
    def initialize(*queues)
      @queues = queues.flatten
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
  end
end
