require_relative "kestrel/connection"
require "securerandom"

module Qu
  module Backend
    class Kestrel < Base
      attr_accessor :abort_timeout

      def initialize
        self.abort_timeout = 10 * 60 * 1_000 # 10 minutes in milliseconds
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        item = dump(payload.attributes_for_push)
        connection.put(payload.queue, [item])
        payload
      end

      def complete(payload)
        connection.confirm(payload.queue, [payload.message]) if payload.message
      end

      def abort(payload)
        connection.abort(payload.queue, [payload.message]) if payload.message
      end

      def fail(payload)
        connection.abort(payload.queue, [payload.message]) if payload.message
      end

      def pop(queue_name = 'default')
        options = {
          abort_timeout: @abort_timeout,
        }
        if message = connection.get(queue_name, options)[0]
          payload = Payload.new(load(message.data))
          payload.message = message
          return payload
        end
      end

      def size(queue_name = 'default')
        connection.size(queue_name)
      end

      def clear(queue_name = 'default')
        connection.flush(queue_name)
      end

      def connection
        @connection ||= Connection.new
      end
    end
  end
end
