require 'digest/sha1'

module Qu
  module Backend
    class AWS < Base
      # Seconds to wait before looking for more jobs when the queue is empty (default: 5)
      attr_accessor :poll_frequency

      def initialize
        self.poll_frequency  = 5
      end

      def push(payload)
        # id does not really matter for aws as they have ids already so i'm just
        # sending something relatively unique for errors and what not
        payload.id = Digest::SHA1.hexdigest(payload.to_s + Time.now.to_s)

        connection.enqueue(payload.queue, encode(payload.attributes))

        logger.debug { "Enqueued job #{payload}" }
        payload
      end

      def pop(worker)
        worker.queues.each do |queue_name|
          logger.debug { "Reserving job in queue #{queue_name}" }

          if message = connection.dequeue(queue_name)
            doc = decode(message.body)
            payload = Payload.new(doc)
            payload.message = message
            return payload
          end
        end

        nil
      end

      def complete(payload)
        payload.message.delete
      end

      def abort(payload)
        payload.message.delete
        connection.enqueue(payload.queue, encode(payload.attributes))
      end

      def size(queue_name = 'default')
        connection.depth(queue_name)
      end

      def clear(queue_name = 'default')
        connection.drain(queue_name)
      end

      def connection
        @connection ||= AWS::Connection.new
      end
    end
  end
end

require 'qu/backend/aws/connection'
