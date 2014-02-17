require 'forwardable'
require 'monitor'

module Qu
  module Util
    class ThreadSafeHash
      include Enumerable
      extend Forwardable

      def_delegator :@monitor, :synchronize
      def_delegators :@items, :size, :[]

      def initialize(original = {})
        @items = original.dup
        @monitor = Monitor.new
      end

      def each( &block )
        synchronize { @items.each(&block) }
      end

      def []=(key,value)
        synchronize { @items[key] = value }
      end

      def delete(value)
        synchronize { @items.delete(value) }
      end

      def values
        synchronize { @items.values }
      end
    end
  end
end
