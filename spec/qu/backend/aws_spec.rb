# To run the tests for this you need to have fake_sqs running.
# You can fire it up like this:
#
#   bundle exec fake_sqs -p 5111
#
require 'spec_helper'
require 'net/http'
require 'qu-aws'

AWS.config(
  use_ssl:            false,
  sqs_endpoint:       'localhost',
  sqs_port:           5111,
  access_key_id:      'asdf',
  secret_access_key:  'asdf',
)

describe Qu::Backend::AWS do
  def reset_service(service)
    host = AWS.config.send("#{service}_endpoint")
    port = AWS.config.send("#{service}_port")
    Net::HTTP.new(host, port).request(Net::HTTP::Delete.new("/"))
  end

  before(:each) do
    [
      :sqs,
    ].each do |service|
      reset_service(service) if service_running?(service)
    end
  end

  it_should_behave_like 'a backend', :services => :sqs
end
