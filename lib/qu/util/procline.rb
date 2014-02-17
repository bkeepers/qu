module Qu
  module Util
    class Procline
      def self.set(message)
        $0 = "qu-#{Qu::VERSION}: #{message}"
      end
    end
  end
end