module Qu
  module Runner
    class Direct

      def run( payload )
        payload.perform
      end

    end
  end
end