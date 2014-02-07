require 'digest/sha1'
require 'aws/sqs'

module Qu
  module Backend
    class SQS < Base

      def push(payload)
        find_or_create_queue(payload.queue).send_message(generate_dump(payload))
        payload
      end

      def batch_push(payloads)
        map_by_queue(payloads) do |queue,group|
          messages = group.map { |payload| generate_dump(payload) }
          find_or_create_queue(queue).batch_send(*messages)
        end.flatten
      end

      def complete(payload)
        payload.message.delete if payload.message
      end

      def batch_complete(payloads)
        begin
          map_by_queue(payloads) do |queue,group|
            connection.queues.named(queue).batch_delete(*group)
          end
        rescue ::AWS::SQS::Errors::NonExistentQueue
        end
      end

      def abort(payload)
        payload.message.visibility_timeout = 0 if payload.message
      end

      def fail(payload)
        payload.message.visibility_timeout = 0 if payload.message
      end

      def pop(queue_name = 'default')
        begin
          queue = connection.queues.named(queue_name)
          create_payload(queue.receive_message)
        rescue ::AWS::SQS::Errors::NonExistentQueue
        end
      end

      def batch_pop( queue_name = 'default', limit = 10 )
        begin
          queue = connection.queues.named(queue_name)
          queue.receive_messages( :limit => limit ).map { |message| create_payload(message) }
        rescue ::AWS::SQS::Errors::NonExistentQueue
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

      def find_or_create_queue(queue_name)
        begin
          connection.queues.named(queue_name)
        rescue ::AWS::SQS::Errors::NonExistentQueue
          connection.queues.create(queue_name)
        end
      end

      def create_payload(message)
        if message
          doc = load(message.body)
          payload = Payload.new(doc)
          payload.message = message
          payload
        end
      end

      def generate_dump(payload)
        dump(set_message_id(payload).attributes_for_push)
      end

      def map_by_queue( payloads )
        return unless payloads
        payloads.group_by { |p| p.queue }.map do |queue,group|
          yield(queue,group)
        end
      end

      def set_message_id(payload)
        # id does not really matter for sqs as they have ids already so i'm just
        # sending something relatively unique for errors and what not
        payload.id = Digest::SHA1.hexdigest(payload.to_s + Time.now.to_s)
        payload
      end

    end
  end
end
