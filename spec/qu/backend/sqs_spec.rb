# To run the tests for this you need to have fake_sqs running.
# You can fire it up like this:
#
#   bundle exec fake_sqs -p 5111
#
require 'spec_helper'
require 'net/http'
require 'qu-sqs'

AWS.config(
  use_ssl:            false,
  sqs_endpoint:       'localhost',
  sqs_port:           5111,
  access_key_id:      'asdf',
  secret_access_key:  'asdf',
)

describe Qu::Backend::SQS do
  def reset_service(service)
    host = AWS.config.send("#{service}_endpoint")
    port = AWS.config.send("#{service}_port")
    Net::HTTP.new(host, port).request(Net::HTTP::Delete.new("/"))
  end

  if Qu::Specs.perform?(described_class, :sqs)
    before(:each) do
      reset_service(:sqs)
      subject.connection.queues.create(SimpleJob.queue)
    end

    it_should_behave_like 'a backend'
    it_should_behave_like 'a backend interface'
  end
end
