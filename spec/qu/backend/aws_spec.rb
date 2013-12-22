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

  before(:each) do |ex|
    [
      :sqs,
      :dynamo_db,
    ].each do |service|
      reset_service(service)
    end

    ENV["QU_DYNAMO_TABLE_NAME"] = "qu_test"

    dynamo.tables.create(ENV["QU_DYNAMO_TABLE_NAME"], 10, 5, {
      :hash_key => {:namespace => :string},
      :range_key => {:id => :string},
    })
  end

  it_should_behave_like 'a backend'
end
