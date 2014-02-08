# To run the tests for this you need to have fake_sqs running.
# You can fire it up like this:
#
#   bundle exec fake_sqs -p 5111
#
require 'spec_helper'
require 'net/http'
require 'qu-sqs'

Qu::Specs.setup_fake_sqs

describe Qu::Backend::SQS do

  if Qu::Specs.perform?(described_class, :sqs)
    before(:each) do
      Qu::Specs.reset_service(:sqs)
    end

    it_should_behave_like 'a backend'
    it_should_behave_like 'a backend interface'
    it_should_behave_like 'a batch capable backend'
  end
end
