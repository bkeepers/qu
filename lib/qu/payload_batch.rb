module Qu
  class PayloadBatch
    include Enumerable
    extend Forwardable

    def_delegators :batch, :each, :size

    def initialize(*payloads)
      append(*payloads)
    end

    def batch
      @batch ||= []
    end

    def append(*payloads)
      batch.push(*payloads.flatten)
    end
    alias_method :<<, :append

    def perform
      batch.each do |payload|
        payload.perform
      end
    end

    def to_s
      batch.map { |payload| payload.to_s }.inspect
    end
  end
end
