require 'aws/sqs'
require 'securerandom'

module Qu
  module Queues
    class SQS < Base
      def initialize(name = "default")
        self.name = name
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        queue.send_message(dump(payload.attributes_for_push))
        payload
      end

      def complete(payload)
        payload.message.delete if payload.message
      end

      def abort(payload)
        payload.message.visibility_timeout = 0 if payload.message
      end

      def fail(payload)
        payload.message.visibility_timeout = 0 if payload.message
      end

      def pop
        if message = queue.receive_message
          doc = load(message.body)
          payload = Payload.new(doc)
          payload.message = message
          payload
        end
      end

      def size
        queue.visible_messages
      end

      def clear
        messages = []
        begin
          begin
            messages = queue.receive_message(:limit => 10)
            queue.batch_delete(messages)
          rescue ::AWS::SQS::Errors::BatchDeleteSend
          end
        end while messages.size > 0
      end

      def connection
        @connection ||= ::AWS::SQS.new
      end

      def queue
        @queue ||= connection.queues.named(name.to_s)
      end
    end
  end
end
