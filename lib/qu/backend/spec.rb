class SimpleJob < Qu::Job
  def perform
  end
end

class CustomQueue < Qu::Job
  queue :custom
end

shared_examples_for 'a backend' do
  let(:job) { SimpleJob }

  before(:all) do
    Qu.backend = described_class.new
  end

  before do
    subject.clear
  end

  describe 'enqueue' do
    it 'should return a job id' do
      subject.enqueue(job).should_not be_nil
    end

    it 'should add a job to the queue' do
      subject.enqueue(job)
      subject.length(job.queue).should == 1
    end

    it 'should add queue to list of queues' do
      subject.queues.should == []
      subject.enqueue job
      subject.queues.should == [job.queue]
    end

    it 'should assign a different job id for the same job enqueue multiple times' do
      id = subject.enqueue(job)
      subject.enqueue(job.clone).should_not == id
    end
  end

  describe 'clear' do
    it 'should clear jobs for given queue' do
      subject.enqueue job
      subject.length(job.queue).should == 1
      subject.clear(job.queue)
      subject.length(job.queue).should == 0
      subject.queues.should_not include(job.queue)
    end

    it 'should not clear jobs for a different queue' do
      subject.enqueue job
      subject.clear('other')
      subject.length(job.queue).should == 1
    end

    it 'should clear all queues without any args' do
      subject.enqueue job
      job.stub!(:queue).and_return('other')
      subject.enqueue job
      subject.length(job.queue).should == 1
      subject.length('other').should == 1
      subject.clear
      subject.length(job.queue).should == 0
      subject.length('other').should == 0
    end
  end

  describe 'reserve' do
    let(:worker) { Qu::Worker.new(job.queue) }

    before do
      @id = subject.enqueue job
    end

    it 'should return next job' do
      subject.reserve(worker).id.should == @id
    end

    it 'should not return an already reserved job' do
      another_job = SimpleJob
      subject.enqueue another_job

      subject.reserve(worker).id.should_not == subject.reserve(worker).id
    end

    it 'should return next job in given queues' do
      subject.enqueue SimpleJob
      job_id = subject.enqueue CustomQueue
      subject.enqueue SimpleJob

      worker = Qu::Worker.new('custom', 'default')

      subject.reserve(worker).id.should == job_id
    end

    it 'should not return job from different queue' do
      worker = Qu::Worker.new('video')
      timeout { subject.reserve(worker) }.should be_nil
    end

    it 'should block by default if no jobs available' do
      subject.clear
      timeout(1) do
        subject.reserve(worker)
        fail("#reserve should block")
      end
    end

    it 'should not block if :block option is set to false' do
      timeout(1) do
        subject.reserve(worker, :block => false)
        true
      end.should be_true
    end

    def timeout(count = 0.1, &block)
      SystemTimer.timeout(count, &block)
    rescue Timeout::Error
      nil
    end
  end
end
