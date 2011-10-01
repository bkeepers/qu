require 'spec_helper'
require 'qu-mongo'

describe Qu::Backend::Mongo do
  it_should_behave_like 'a backend'

  before do
    ENV.delete('MONGOHQ_URL')
  end

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

  describe 'reserve' do
    let(:worker) { Qu::Worker.new }

    describe "on mongo >=2" do
      it 'should return nil when no jobs exist' do
        subject.clear
        Mongo::Collection.any_instance.should_receive(:find_and_modify).and_return(nil)
        lambda { subject.reserve(worker, :block => false).should be_nil }.should_not raise_error
      end
    end

    describe 'on mongo <2' do
      it 'should return nil when no jobs exist' do
        subject.clear
        Mongo::Collection.any_instance.should_receive(:find_and_modify).and_raise(Mongo::OperationFailure)
        lambda { subject.reserve(worker, :block => false).should be_nil }.should_not raise_error
      end
    end
  end
end
