require 'spec_helper'
require 'qu-redis'

describe Qu::Backend::Redis do
  it_should_behave_like 'a backend', :services => :redis

  let(:worker) { Qu::Worker.new('default') }

  if service_running?(:redis)
    describe 'completed' do
      it 'should delete job' do
        subject.push(Qu::Payload.new(:klass => SimpleJob))
        job = subject.reserve(worker)
        subject.connection.exists("job:#{job.id}").should be_true
        subject.completed(job)
        subject.connection.exists("job:#{job.id}").should be_false
      end
    end

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
        subject.namespace = :foobar
        subject.connection.namespace.should == :foobar
      end
    end

    describe 'clear' do
      it 'should delete jobs' do
        payload = Qu::Payload.new(:klass => SimpleJob)
        job = subject.push(payload)
        subject.connection.exists("job:#{job.id}").should be_true
        subject.clear(payload.queue)
        subject.connection.exists("job:#{job.id}").should be_false
      end
    end
  end
end
