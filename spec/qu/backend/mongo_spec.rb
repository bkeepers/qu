require 'spec_helper'
require 'qu-mongo'

describe Qu::Backend::Mongo do
  it_should_behave_like 'a backend', :services => :mongo

  if service_running?(:mongo)
    describe 'connection' do
      it 'should default the qu database' do
        subject.connection.should be_instance_of(Mongo::DB)
        subject.connection.name.should == 'qu'
      end

      it 'should use MONGOHQ_URL from heroku' do
        begin
          Mongo::MongoClient.any_instance.stub(:connect)
          ENV['MONGOHQ_URL'] = 'mongodb://user:pw@host:10060/quspec'
          subject.connection.name.should == 'quspec'
          # debugger
          subject.connection.connection.host_port.should == ['host', 10060]
          subject.connection.connection.auths.should satisfy { |v|
            # Not happy about this, but the format of the auths attribute differs depending on your installed mongo version
            # mongo >= 1.8.4 uses symbols for hash keys
            # mongo < 1.8.4 uses strings for hash keys
            v == [{:db_name => 'quspec', :username => 'user', :password => 'pw'}] or
            v ==  [{'db_name' => 'quspec', 'username' => 'user', 'password' => 'pw'}]
          }
        ensure
          ENV.delete('MONGOHQ_URL')
        end
      end

      context "Connection Failure" do
        let(:retries_number) { 3 }
        let(:retries_frequency) { 5 }

        before do
          subject.max_retries = retries_number
          subject.retry_frequency = retries_frequency

          Mongo::Collection.any_instance.stub(:count).and_raise(Mongo::ConnectionFailure)
          subject.stub(:sleep)
        end

        it "raise error" do
          expect { subject.length }.to raise_error(Mongo::ConnectionFailure)
        end

        it "trying to reconnect" do
          subject.connection.should_receive(:[]).exactly(4).times.and_raise(Mongo::ConnectionFailure)
          expect { subject.length }.to raise_error
        end

        it "sleep between tries" do
          subject.should_receive(:sleep).with(5).ordered
          subject.should_receive(:sleep).with(10).ordered
          subject.should_receive(:sleep).with(15).ordered

          expect { subject.length }.to raise_error
        end

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
end
