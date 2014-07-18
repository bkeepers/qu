require 'securerandom'

module Qu
  module Queues
    class Immediate < Base
      def push(payload)
        payload.id = SecureRandom.uuid
        payload.perform
      end
    end
  end
end
