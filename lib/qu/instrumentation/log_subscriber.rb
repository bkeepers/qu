require 'securerandom'
require 'active_support/notifications'
require 'active_support/log_subscriber'

module Qu
  module Instrumentation
    class LogSubscriber < ::ActiveSupport::LogSubscriber
      def pop(event)
        log_event(:pop, event)
      end

      def push(event)
        log_event(:push, event)
      end

      def perform(event)
        log_event(:perform, event)
      end

      def complete(event)
        log_event(:complete, event)
      end

      def abort(event)
        log_event(:abort, event)
      end

      def failure(event)
        log_event(:failure, event)
      end

      private

      def log_event(type, event)
        return unless logger.debug?

        description = "Qu #{type}"
        details = []

        if queue_name = event.payload[:queue_name]
          details << "queue_name=#{queue_name}"
        end

        if payload = event.payload[:payload]
          details << "payload=#{payload}"
        end

        name = '%s (%.1fms)' % [description, event.duration]
        name_color = odd? ? CYAN : MAGENTA

        debug "  #{color(name, name_color, true)}  [ #{details.join(' ')} ]"
      end

      def odd?
        @odd_or_even = !@odd_or_even
      end
    end

    LogSubscriber.logger = Qu.logger
    LogSubscriber.attach_to :qu
  end
end

Qu.configure do |config|
  config.instrumenter = ActiveSupport::Notifications
end
