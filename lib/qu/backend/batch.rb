require 'qu/batch_payload'
require 'qu/backend/wrapper'

module Qu
  module Backend

    # backend that takes messages in bulk for processing
    class Batch
      include Wrapper

      def_delegators :@backend, :size, :clear, :push

      def complete(payload)
        @backend.batch_complete(payload.payloads)
      end

      def abort(payload)
        @backend.batch_abort(payload.payloads)
      end

      def fail(payload)
        @backend.batch_fail(payload.payloads)
      end

      def pop(queue_name = 'default')
        payloads = @backend.batch_pop( queue_name, 10 ) # size should be configurable
        if payloads && !payloads.empty?
          result = payloads.group_by { |payload| payload.klass }.map do |klass,payloads|
            Qu::BatchPayload.new( :queue => queue_name, :klass => klass, :payloads => payloads )
          end

          current = result.shift

          result.each do |payload|
            @backend.batch_push(payload.payloads)
          end

          current
        end
      end

    end
  end
end