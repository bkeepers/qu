module Qu
  module Util
    class SignalHandler

      def self.trap( *signals, &block )
        signals.each do |signal|
          Signal.trap(signal) do
            block.call(signal)
          end
        end
      end

      def self.clear(*signals)
        signals.each do |signal|
          begin
            Signal.trap(signal, 'DEFAULT')
          rescue ArgumentError => e
            warn "Could not trap signal #{signal} - #{e}"
          end
        end
      end

    end
  end
end