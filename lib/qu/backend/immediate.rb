module Qu
  module Backend
    class Immediate < Base
      def push(payload)
        payload.perform
      end

      def pop(*)
      end

      def complete(payload)
      end

      def abort(payload)
      end

      def clear(queue)
      end

      def size(*)
        0
      end
    end
  end
end
