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
end
