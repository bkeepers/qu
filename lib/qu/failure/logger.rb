require 'logger'

module Qu
  module Failure
    class Logger
      extend ::Qu::Logger

      def self.create(job, exception)
        logger.fatal "qu_job_failed: job=#{job.payload.to_s} exception=#{exception}"
        log_exception(exception)
      end
    end
  end
end
