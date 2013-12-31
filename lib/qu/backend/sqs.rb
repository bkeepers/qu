require 'digest/sha1'
require 'aws/sqs'

module Qu
  module Backend
    class SQS < Base
      def push(payload)
        # id does not really matter for sqs as they have ids already so i'm just
        # sending something relatively unique for errors and what not
        payload.id = Digest::SHA1.hexdigest(payload.to_s + Time.now.to_s)

        queue = begin
          connection.queues.named(payload.queue)
        rescue ::AWS::SQS::Errors::NonExistentQueue
          connection.queues.create(payload.queue)
        end

        queue.send_message(dump(payload.attributes_for_push))
        payload
      end

      def pop(queue_name = 'default')
        begin
          queue = connection.queues.named(queue_name)

          if message = queue.receive_message
            doc = load(message.body)
            payload = Payload.new(doc)
            payload.message = message
            return payload
          end
        rescue ::AWS::SQS::Errors::NonExistentQueue
        end
      end

      def complete(payload)
        payload.message.delete if payload.message
      end

      def abort(payload)
        if fake_sqs?
          # should only get here in localhost; it is ok to remove this when
          # fake_sqs supports changing a messages visibility timeout
          payload.message.delete if payload.message
          push(payload)
        else
          payload.message.visibility_timeout = 0
        end
      end

      def size(queue_name = 'default')
        begin
          connection.queues.named(queue_name).visible_messages
        rescue ::AWS::SQS::Errors::NonExistentQueue
          0
        end
      end

      def clear(queue_name = 'default')
        begin
          queue = connection.queues.named(queue_name)
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

      def connection
        @connection ||= ::AWS::SQS.new
      end

      private

      def fake_sqs?
        ::AWS.config.sqs_endpoint == "localhost"
      end
    end
  end
end
