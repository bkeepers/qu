require 'spec_helper'
require 'qu-mongo'

describe Qu::Backend::Mongo do
  it_should_behave_like 'a backend'

  describe 'connection' do
    it 'should default the qu database' do
      subject.connection.should be_instance_of(Mongo::DB)
      subject.connection.name.should == 'qu'
    end

    it 'should use MONGOHQ_URL from heroku' do
      Mongo::Connection.any_instance.stub(:connect)
      ENV['MONGOHQ_URL'] = 'mongodb://user:pw@host:10060/quspec'
      subject.connection.name.should == 'quspec'
      # debugger
      subject.connection.connection.host_to_try.should == ['host', 10060]
      subject.connection.connection.auths.should == [{'db_name' => 'quspec', 'username' => 'user', 'password' => 'pw'}]
    end

  end
end
