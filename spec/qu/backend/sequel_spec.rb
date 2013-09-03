require 'spec_helper'
require 'qu-sequel'

describe Qu::Backend::Sequel do
  database_url = 'postgres://postgres:@localhost/qu_test'
  let(:connection) { subject.database }

  it_should_behave_like 'a backend'

  before(:all) do
    ENV['DATABASE_URL'] = database_url

    connection = ::Sequel.connect(database_url)
    described_class.create_tables(connection)
    connection.disconnect
  end

  before do
    connection[described_class::JOB_TABLE_NAME].delete
    connection[described_class::WORKER_TABLE_NAME].delete
  end

  after do
    if connection.is_a?(::Sequel::Database)
      connection.disconnect
    end
  end
end
