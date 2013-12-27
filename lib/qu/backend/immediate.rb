module Qu
  module Backend
    class Immediate < Base
      def push(queue_name, payload)
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

      def queues(*)
        ["default"]
      end
    end
  end
end
