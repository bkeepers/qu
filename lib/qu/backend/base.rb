require 'multi_json'

module Qu
  module Backend
    class Base

    private

      def encode(data)
        MultiJson.encode(data)
      end

      def decode(data)
        MultiJson.decode(data)
      end
    end
  end
end