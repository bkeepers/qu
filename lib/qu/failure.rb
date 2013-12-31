require "qu/failure/log"
require "qu/instrumenter"

module Qu
  module Failure
    extend Qu::Instrumenter

    def self.create(payload, exception)
      instrument("failure.#{InstrumentationNamespace}") do |ipayload|
        ipayload[:payload] = payload
        ipayload[:exception] = exception

        backend.create(payload, exception)
      end
    end

    def self.backend=(backend)
      @backend = backend
    end

    def self.backend
      @backend ||= Failure::Log
    end
  end
end
