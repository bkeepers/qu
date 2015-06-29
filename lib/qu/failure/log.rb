require "qu/logger"

module Qu
  module Failure
    class Log
      extend ::Qu::Logger

      def self.report(payload, exception)
        logger.fatal "Qu failure #{payload.to_s}"
        log_exception(exception)
      end
    end
  end
end
