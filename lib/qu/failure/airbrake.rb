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
          'request' => {
            'parameters' => {
              'id'    => job.id,
              'queue' => job.queue,
              'args'  => job.args,
              'class' => job.klass.to_s
            }            
          },

          'rescue_block' => {
            'name'    => job.klass.to_s
          }
        }
      end
    end
  end
end
