require 'spec_helper'
require 'qu-redis'

describe Qu::Queues::Redis do
  if Qu::Specs.perform?(described_class, :redis)
    it_should_behave_like 'a queue'
    it_should_behave_like 'a queue interface'

    describe 'connection' do
      it 'should create default connection if one not provided' do
        subject.connection.should be_instance_of(Redis::Namespace)
        subject.connection.namespace.should == :qu
      end

      it 'should use REDISTOGO_URL from heroku with namespace' do
        begin
          ENV['REDISTOGO_URL'] = 'redis://0.0.0.0:9876'
          subject.connection.client.host.should == '0.0.0.0'
          subject.connection.client.port.should == 9876
          subject.connection.namespace.should == :qu
        ensure
          ENV.delete 'REDISTOGO_URL'
        end
      end

      it 'should allow customizing the namespace' do
        instance = Qu::Queues::Redis.new("default", :foobar)
        instance.connection.namespace.should eq(:foobar)
      end
    end
  end
end
