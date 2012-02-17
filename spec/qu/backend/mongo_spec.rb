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

    context "Connection Failure" do
      let(:retries_number) { 3 }
      let(:retries_frequency) { 5 }

      before do
        subject.max_retries = retries_number
        subject.retry_frequency = retries_frequency

        Mongo::DB.any_instance.stub(:[]).and_raise(Mongo::ConnectionFailure)
        subject.stub(:sleep)
      end

      it "raise error" do
        expect { subject.queues }.to raise_error(Mongo::ConnectionFailure)
      end

      it "trying to reconect" do
        subject.database.should_receive(:[]).exactly(4).times.and_raise(Mongo::ConnectionFailure)
        expect { subject.queues }.to raise_error
      end

      it "sleep between tries" do
        subject.should_receive(:sleep).with(5).ordered
        subject.should_receive(:sleep).with(10).ordered
        subject.should_receive(:sleep).with(15).ordered

        expect { subject.queues }.to raise_error
      end

    end
  end

  describe 'failure' do
    let(:payload) { Qu::Payload.new(:id => '1', :klass => SimpleJob) }

    it 'should store the exception, error and backtrace' do
      jobs = mock('jobs')
      subject.stub(:jobs).and_return(jobs)
      jobs.should_receive(:insert) do |attrs|
        attrs[:exception].should eql 'Exception'
        attrs[:error].should eql 'an error'
        attrs[:backtrace].should eql nil
      end
      subject.failed(payload, Exception.new('an error'))
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
