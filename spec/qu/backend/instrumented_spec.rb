# To run the tests for this you need to have fake_sqs running.
# You can fire it up like this:
#
#   bundle exec fake_sqs -p 5111
#
require 'spec_helper'
require 'qu/backend/instrumented'
require 'qu-redis'

describe Qu::Backend::Instrumented do
  subject {
    described_class.new(Qu::Backend::Redis.new)
  }

  it_should_behave_like 'a backend', :services => :redis
  it_should_behave_like 'a backend interface'
end
