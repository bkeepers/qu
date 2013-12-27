require 'digest/sha1'

module Qu
  module Backend
    class AWS < Base
      def self.fake_sqs?
        ::AWS.config.sqs_endpoint == "localhost"
      end

      def push(queue_name, payload)
        # id does not really matter for aws as they have ids already so i'm just
        # sending something relatively unique for errors and what not
        payload.id = Digest::SHA1.hexdigest(payload.to_s + Time.now.to_s)
        connection.push(queue_name, dump(payload.attributes))
        payload
      end

      def pop(queue_name = 'default')
        if message = connection.pop(queue_name)
          doc = load(message.body)
          payload = Payload.new(doc)
          payload.message = message
          return payload
        end
      end

      def complete(payload)
        connection.complete(payload)
      end

      def abort(payload)
        connection.abort(payload)
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
