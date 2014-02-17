require 'securerandom'

module Qu
  module Backend
    class Immediate < Base
      def push(payload)
        payload.id = SecureRandom.uuid
        payload.perform
      end

      def complete(payload)
      end

      def abort(payload)
      end

      def fail(payload)
      end

      def pop(queue = 'default')
      end

      def size(queue = 'default')
        0
      end

      def clear(queue = 'default')
      end
    end
  end
end
