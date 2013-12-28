module Qu
  module Backend
    class Immediate < Base
      def push(payload)
        payload.perform
      end

      def complete(payload)
      end

      def abort(payload)
      end

      def pop(queue)
      end

      def size(queue)
        0
      end

      def clear(queue)
      end
    end
  end
end
