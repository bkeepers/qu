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

        def push(queue_name, body)
          publisher.publish(queue_name, body)
        end

        def pop(queue_name)
          subscriber.receive(queue_name)
        end

        def complete(payload)
          payload.message.delete
        end

        def abort(payload)
          payload.message.delete
          push(payload.queue, AWS.dump(payload.attributes))
        end

        def size(queue_name)
          subscriber.size(queue_name)
        end

        def clear(queue_name)
          subscriber.clear(queue_name)
        end
      end
    end
  end
end
