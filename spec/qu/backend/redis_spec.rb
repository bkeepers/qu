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
end
