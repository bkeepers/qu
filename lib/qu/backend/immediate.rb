require 'digest/sha1'

module Qu
  module Backend
    class Immediate < Base
      def push(payload)
        # id does not really matter for immediate so i'm just sending something
        # relatively unique for errors and what not
        payload.id = Digest::SHA1.hexdigest(payload.to_s + Time.now.to_s)
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

      def reconnect
      end

    end
  end
end
