module Qu
  module Instrumentation
    class Subscriber
      # Public: Use this as the subscribed block.
      def self.call(name, start, ending, transaction_id, payload)
        new(name, start, ending, transaction_id, payload).update
      end

      # Private: Initializes a new event processing instance.
      def initialize(name, start, ending, transaction_id, payload)
        @name = name
        @start = start
        @ending = ending
        @payload = payload
        @duration = ending - start
        @transaction_id = transaction_id
      end

      # Internal: Override in subclass.
      def update_timer(metric)
        raise 'not implemented'
      end

      # Internal: Override in subclass.
      def update_counter(metric)
        raise 'not implemented'
      end

      # Private
      def update
        op = @name.split('.', 2).first
        return unless op

        update_timer "qu.op.#{op}"

        case op
        when "push"
          if payload = @payload[:payload]
            update_timer "qu.queue.#{payload.queue}.#{op}"
            update_timer "qu.job.#{payload.klass}.#{op}"
          end
        when "pop"
          if queue_name = @payload[:queue_name]
            update_timer "qu.queue.#{queue_name}.#{op}"
          end
        else
          if payload = @payload[:payload]
            update_timer "qu.job.#{payload.klass}.#{op}"
          end
        end
      end
    end
  end
end
