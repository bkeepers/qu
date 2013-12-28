require 'securerandom'
require 'active_support/notifications'
require 'active_support/log_subscriber'

module Qu
  module Instrumentation
    class LogSubscriber < ::ActiveSupport::LogSubscriber
      def pop(event)
        return unless logger.debug?

        queue_name = event.payload[:queue_name]
        empty = event.payload[:empty]

        description = "Qu pop"
        details = "queue_name=#{queue_name} empty=#{empty}"

        name = '%s (%.1fms)' % [description, event.duration]
        name_color = odd? ? CYAN : MAGENTA

        debug "  #{color(name, name_color, true)}  [ #{details} ]"
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

        payload = event.payload[:payload]

        description = "Qu #{type}"
        details = "payload=#{payload}"
        details += " exception=#{event.payload[:exception]}" if type == :failure

        name = '%s (%.1fms)' % [description, event.duration]
        name_color = odd? ? CYAN : MAGENTA

        debug "  #{color(name, name_color, true)}  [ #{details} ]"
      end

      def odd?
        @odd_or_even = !@odd_or_even
      end
    end
  end
end

Qu::Instrumentation::LogSubscriber.attach_to :qu
