require 'digest/sha1'

module Qu
  module Backend
    class AWS < Base
      # Seconds to wait before looking for more jobs when the queue is empty (default: 5)
      attr_accessor :poll_frequency

      def initialize
        self.poll_frequency  = 5
      end

      def push(queue_name, payload)
        # id does not really matter for aws as they have ids already so i'm just
        # sending something relatively unique for errors and what not
        payload.id = Digest::SHA1.hexdigest(payload.to_s + Time.now.to_s)
        connection.push(queue_name, encode(payload.attributes))
        payload
      end

      def pop(queue_name = 'default')
        if message = connection.pop(queue_name)
          doc = decode(message.body)
          payload = Payload.new(doc)
          payload.message = message
          return payload
        end
      end

      def complete(payload)
        payload.message.delete
      end

      def abort(payload)
        payload.message.delete
        connection.push(payload.queue, encode(payload.attributes))
      end

      def size(queue_name = 'default')
        connection.size(queue_name)
      end

      def clear(queue_name = 'default')
        connection.clear(queue_name)
      end

      def connection
        @connection ||= AWS::Connection.new
      end
    end
  end
end

require 'qu/backend/aws/connection'
