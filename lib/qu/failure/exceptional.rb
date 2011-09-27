require 'exceptional'

module Qu
  module Failure
    class Exceptional
      extend Logger

      def self.create(job, exception)
        if ::Exceptional::Config.should_send_to_api?
          logger.debug "Reporting error to Exceptional"
          ::Exceptional::Remote.error(ExceptionData.new(job, exception))
        else
          logger.debug "Not reporting error to exceptional"
        end
      end

      class ExceptionData < ::Exceptional::ExceptionData
        def initialize(job, exception)
          @job = job
          super(exception)
        end

        def extra_stuff
          {
            'request' => {
              'parameters' => {
                'id'    => @job.id,
                'queue' => @job.queue,
                'args'  => @job.args,
                'class' => @job.klass.to_s
              }
            },

            'rescue_block' => {
              'name'    => @job.klass.to_s
            }
          }
        end
      end
    end
  end
end
