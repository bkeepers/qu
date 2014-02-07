require 'qu/payload'

module Qu
  class BatchPayload < Payload

    def initialize( options )
      super
      self.args = self.payloads.map(&:args).flatten
    end

  end
end