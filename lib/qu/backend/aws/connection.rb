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

        def enqueue(queue_name, body)
          publisher.publish(queue_name, body)
        end

        def dequeue(queue_name)
          subscriber.receive(queue_name)
        end

        def depth(queue_name)
          subscriber.depth(queue_name)
        end

        def drain(queue_name)
          subscriber.drain(queue_name)
        end
      end
    end
  end
end
