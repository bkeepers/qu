require 'spec_helper'
require 'qu-redis'

describe Qu::Backend::Redis do
  it_should_behave_like 'a backend'

  let(:worker) { Qu::Worker.new('default') }

  describe 'completed' do
    it 'should delete job' do
      subject.enqueue(Qu::Payload.new(:klass => SimpleJob))
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
      job = subject.enqueue(Qu::Payload.new(:klass => SimpleJob))
      subject.redis.exists("job:#{job.id}").should be_true
      subject.clear
      subject.redis.exists("job:#{job.id}").should be_false
    end
  end
end
