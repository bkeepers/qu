require 'qu/backend/aws/sqs/client'

module Qu
  module Backend
    class AWS
      class SQS
        class Subscriber < Client
          def receive(queue_name)
            begin
              queue = sqs.queues.named(queue_name)
              queue.receive_message
            rescue ::AWS::SQS::Errors::NonExistentQueue
            end
          end

          def size(queue_name = 'default')
            begin
              sqs.queues.named(queue_name).visible_messages
            rescue ::AWS::SQS::Errors::NonExistentQueue
              0
            end
          end

          def clear(queue_name = 'default')
            begin
              queue = sqs.queues.named(queue_name)
              messages = []
              begin
                begin
                  messages = queue.receive_message(:limit => 10)
                  queue.batch_delete(messages)
                rescue ::AWS::SQS::Errors::BatchDeleteSend
                end
              end while messages.size > 0
            rescue ::AWS::SQS::Errors::NonExistentQueue
              # doesn't exist so no need to flush
            end
          end
        end
      end
    end
  end
end
