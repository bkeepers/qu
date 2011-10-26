require 'airbrake'

module Qu
  module Failure
    class Airbrake
      extend Logger

      def self.create(job, exception)
        logger.debug "Reporting error to Airbrake"
        ::Airbrake.notify_or_ignore(exception, extra_stuff(job))
      end
      
      def self.extra_stuff job
        {
          :parameters => {
            :id     => job.id,
            :queue  => job.queue,
            :args   => job.args,
            :class  => job.klass.to_s
          }
        }
      end
    end
  end
end
