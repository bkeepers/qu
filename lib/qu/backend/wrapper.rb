module Qu
  module Backend
    module Wrapper
      extend Forwardable
      def_delegators :@backend, :connection, :connection=

      def self.included( base )
        base.extend(ClassMethods, Forwardable)
      end

      def initialize(backend)
        @backend = backend
      end

      module ClassMethods

        def wrap(backend)
          if backend.nil?
            backend
          else
            new(backend)
          end
        end

      end

    end
  end
end