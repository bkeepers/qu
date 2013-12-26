module Qu
  module Backend
    class Immediate < Base
      def enqueue(payload)
        payload.perform
      end

      def completed(payload)
      end

      def release(payload)
      end

      def clear(queue)
      end

      def connection=(*)
      end

      def reserve(*)
      end

      def length(*)
        0
      end

      def queues(*)
        ["default"]
      end
    end
  end
end
