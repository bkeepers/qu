require 'securerandom'

module Qu
  module Backend
    class Immediate < Base
      def push(payload)
        payload.id = SecureRandom.uuid
        payload.perform
      end
    end
  end
end
