require 'multi_json'

module Qu
  module Backend
    class Base

    private

      def encode(data)
        MultiJson.encode(data) if data
      end

      def decode(data)
        MultiJson.decode(data) if data
      end
    end
  end
end