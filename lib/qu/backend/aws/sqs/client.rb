require 'aws/sqs'

module Qu
  module Backend
    class AWS
      class SQS
        class Client
          # Private
          attr_reader :sqs

          def initialize(options = {})
            @sqs = options.fetch(:sqs) { ::AWS::SQS.new }
          end
        end
      end
    end
  end
end
