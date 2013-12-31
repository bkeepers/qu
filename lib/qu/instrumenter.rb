require "forwardable"

module Qu
  module Instrumenter
    extend Forwardable

    def_delegator :"Qu.instrumenter", :instrument
  end
end
