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

      def failed(payload, error)
      end
    end
  end
end
