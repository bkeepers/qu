require 'spec_helper'
require 'qu-redis'

describe Qu::Backend::Redis do
  it_should_behave_like 'a backend'

  let(:worker) { Qu::Worker.new('default') }

  describe 'completed' do
    it 'should delete job' do
      subject.enqueue(SimpleJob)
      job = subject.reserve(worker)
      subject.redis.exists("job:#{job.id}").should be_true
      subject.completed(job)
      subject.redis.exists("job:#{job.id}").should be_false
    end
  end

  describe 'clear_workers' do
    before { subject.register_worker worker }

    it 'should delete worker key' do
      subject.redis.get("worker:#{worker.id}").should_not be_nil
      subject.clear_workers
      subject.redis.get("worker:#{worker.id}").should be_nil
    end
  end

  describe 'connection' do
    it 'should use the qu connection' do
      Qu.connection = mock('a connection')
      subject.redis.should == Qu.connection
    end

    it 'should create default connection if one not provided' do
      subject.redis.client.host.should == '127.0.0.1'
      subject.redis.client.port.should == 6379
      subject.redis.namespace.should == :qu
    end

    it 'should use REDISTOGO_URL from heroku with namespace' do
      ENV['REDISTOGO_URL'] = 'redis://0.0.0.0:9876'
      subject.redis.client.host.should == '0.0.0.0'
      subject.redis.client.port.should == 9876
      subject.redis.namespace.should == :qu
    end

    it 'should allow customizing the namespace' do
      subject.namespace = :foobar
      subject.redis.namespace.should == :foobar
    end
  end
end
