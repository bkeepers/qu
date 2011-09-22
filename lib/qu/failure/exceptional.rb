require 'exceptional'

module Qu
  module Failure
    class Exceptional
      def self.create(job, exception)
        if ::Exceptional::Config.should_send_to_api?
          ::Exceptional::Remote.error(ExceptionData.new(job, exception))
        end
      end

      class ExceptionData < ::Exceptional::ExceptionData
        def initialize(job, exception)
          @job = job
          super(exception, 'Qu')
        end

        def framework
          'qu'
        end

        def extra_stuff
          {
            'id'    => @job.id,
            'queue' => @job.queue,
            'args'  => @job.args,
            'class' => @job.klass.to_s
          }
        end
      end
    end
  end
end
