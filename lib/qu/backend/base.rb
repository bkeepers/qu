require 'multi_json'

module Qu
  module Backend
    class Base
      include Logger
      attr_accessor :connection

    private
      # Using MultiJson feature-detection per https://github.com/sferik/rails/commit/5e62670131dfa1718eaf21ff8dd3371395a5f1cc
      def encode(data)
        if data
          MultiJson.respond_to?(:adapter) ? MultiJson.dump(data) : MultiJson.encode(data)
        end
      end

      def decode(data)
        if data
          MultiJson.respond_to?(:adapter) ? MultiJson.load(data) : MultiJson.decode(data)
        end
      end
    end
  end
end
