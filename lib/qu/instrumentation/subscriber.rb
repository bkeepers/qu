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
        payload = @payload[:payload]
        update_timer "qu.#{op}"
        update_timer "qu.#{op}.#{payload.klass}"
      end
    end
  end
end
