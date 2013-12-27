require 'qu/backend/aws/sns/publisher'
require 'qu/backend/aws/sqs/publisher'
require 'qu/backend/aws/sqs/subscriber'

module Qu
  module Backend
    class AWS
      class Connection
        # Private
        attr_reader :publisher

        # Private
        attr_reader :subscriber

        def initialize(options = {})
          @publisher = options.fetch(:publisher) { AWS::SQS::Publisher.new }
          @subscriber = options.fetch(:subscriber) { AWS::SQS::Subscriber.new }
        end

        def push(queue_name, payload)
          publisher.publish(queue_name, AWS.dump(payload.attributes))
        end

        def pop(queue_name)
          subscriber.receive(queue_name)
        end

        def complete(payload)
          payload.message.delete
        end

        def abort(payload)
          if AWS.fake_sqs?
            # should only get here in localhost; it is ok to remove this when
            # fake_sqs supports changing a messages visibility timeout
            payload.message.delete
            push(payload.queue, payload)
          else
            payload.message.visibility_timeout = 0
          end
        end

        def size(queue_name = 'default')
          subscriber.size(queue_name)
        end

        def clear(queue_name = 'default')
          subscriber.clear(queue_name)
        end
      end
    end
  end
end
