require 'qu/backend/aws/sns/client'

module Qu
  module Backend
    class AWS
      class SNS
        class Publisher < Client
          def publish(topic_name, body)
            sns.publish(topic_name, body)
          end
        end
      end
    end
  end
end
