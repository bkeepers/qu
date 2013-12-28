require 'qu/instrumentation/subscriber'
require 'statsd'

module Qu
  module Instrumentation
    class StatsdSubscriber < Subscriber
      class << self
        attr_accessor :client
      end

      def update_timer(metric)
        if self.class.client
          self.class.client.timing metric, (@duration * 1_000).round
        end
      end

      def update_counter(metric)
        if self.class.client
          self.class.client.increment metric
        end
      end
    end
  end
end
