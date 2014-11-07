module Qu
  class Job
    module BatchProcess
      def self.included(base)
        base.send(:include, Enumerable)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        def batch_job?
          true
        end
      end

      def batch
        if payload.respond_to?(:each)
          payload
        else
          payload.nil? ? [] : [payload]
        end
      end

      def each(&block)
        batch.each do |current_payload|
          yield *current_payload.args
        end
      end

      def each_payload(&block)
        batch.each do |current_payload|
          yield current_payload
        end
      end
    end
  end
end
