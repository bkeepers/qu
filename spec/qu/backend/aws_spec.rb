# To run the tests for this you need to have fake_sqs and fake_dynamo running.
# They are included in the gemfile through the aws gemspec as development
# dependencies. You can fire them up like this:
#
#   bundle exec fake_sqs -p 5111
#   bundle exec fake_dynamo -p 5112
#
require 'spec_helper'
require 'net/http'
require 'qu-aws'

AWS.config(
  use_ssl:            false,
  sqs_endpoint:       'localhost',
  sqs_port:           5111,
  dynamo_db_endpoint: 'localhost',
  dynamo_db_port:     5112,
  access_key_id:      'asdf',
  secret_access_key:  'asdf',
)

describe Qu::Backend::AWS do
  let(:dynamo) { AWS::DynamoDB.new }

  def reset_service(service)
    host = AWS.config.send("#{service}_endpoint")
    port = AWS.config.send("#{service}_port")
    Net::HTTP.new(host, port).request(Net::HTTP::Delete.new("/"))
  end

  before(:each) do
    [
      :sqs,
      :dynamo_db,
    ].each do |service|
      reset_service(service) if service_running?(service)
    end

    if service_running?(:dynamo_db)
      ENV["QU_DYNAMO_TABLE_NAME"] = "qu_test"
      dynamo.tables.create(ENV["QU_DYNAMO_TABLE_NAME"], 10, 5, {
        :hash_key => {:namespace => :string},
        :range_key => {:id => :string},
      })
    end
  end

  it_should_behave_like 'a backend', :services => [:sqs, :dynamo_db]
end
