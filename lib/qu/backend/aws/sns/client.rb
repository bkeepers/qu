require 'aws/sns'

module Qu
  module Backend
    class AWS
      class SNS
        class Client
          # Private
          attr_reader :sns

          def initialize(options = {})
            @sns = options.fetch(:sns) { ::AWS::SNS.new }
          end
        end
      end
    end
  end
end
