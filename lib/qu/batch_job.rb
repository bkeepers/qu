module Qu
  class BatchJob < Job
    include Enumerable

    def self.batch_size(size = nil)
      @batch_size = size if size
      @batch_size ||= 1
    end

    def self.batch_job?
      true
    end

    def full?
      batch.size >= self.class.batch_size
    end

    def batch
      @batch ||= []
    end

    def push(*payloads)
      batch.push(*payloads)
    end
    alias_method :<<, :push

    def each(&block)
      batch.each { |payload| yield *payload.args }
    end

    def each_payload(&block)
      batch.each { |payload| yield payload }
    end
  end
end
