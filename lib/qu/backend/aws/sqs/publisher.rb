require 'qu/backend/aws/sqs/client'

module Qu
  module Backend
    class AWS
      class SQS
        class Publisher < Client
          def publish(queue_name, body)
            queue = begin
              sqs.queues.named(queue_name)
            rescue ::AWS::SQS::Errors::NonExistentQueue
              sqs.queues.create(queue_name)
            end

            queue.send_message(body)
          end
        end
      end
    end
  end
end
