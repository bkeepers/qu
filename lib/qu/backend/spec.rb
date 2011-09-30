class SimpleJob
  def self.perform
  end
end

class CustomQueue
  @queue = :custom
end

shared_examples_for 'a backend' do
  let(:worker) { Qu::Worker.new('default') }

  before(:all) do
    Qu.backend = described_class.new
  end

  before do
    subject.clear
    subject.clear_workers
  end

  describe 'enqueue' do
    it 'should return a job id' do
      subject.enqueue(SimpleJob).should be_instance_of(Qu::Payload)
    end

    it 'should add a job to the queue' do
      payload = subject.enqueue(SimpleJob)
      payload.queue.should == 'default'
      subject.length(payload.queue).should == 1
    end

    it 'should add queue to list of queues' do
      subject.queues.should == []
      payload = subject.enqueue(SimpleJob)
      subject.queues.should == [payload.queue]
    end

    it 'should assign a different job id for the same job enqueue multiple times' do
      subject.enqueue(SimpleJob).id.should_not == subject.enqueue(SimpleJob).id
    end
  end

  describe 'length' do
    it 'should use the default queue by default' do
      subject.length.should == 0
      subject.enqueue(SimpleJob)
      subject.length.should == 1
    end
  end

  describe 'clear' do
    it 'should clear jobs for given queue' do
      payload = subject.enqueue SimpleJob
      subject.length(payload.queue).should == 1
      subject.clear(payload.queue)
      subject.length(payload.queue).should == 0
      subject.queues.should_not include(payload.queue)
    end

    it 'should not clear jobs for a different queue' do
      payload = subject.enqueue SimpleJob
      subject.clear('other')
      subject.length(payload.queue).should == 1
    end

    it 'should clear all queues without any args' do
      subject.enqueue(SimpleJob).queue.should == 'default'
      subject.enqueue(CustomQueue).queue.should == 'custom'
      subject.length('default').should == 1
      subject.length('custom').should == 1
      subject.clear
      subject.length('default').should == 0
      subject.length('custom').should == 0
    end

    it 'should clear failed queue without any args' do
      payload = subject.enqueue SimpleJob
      subject.failed(payload, Exception.new)
      subject.length('failed').should == 1
      subject.clear
      subject.length('failed').should == 0
    end

    it 'should not clear failed queue with specified queues' do
      payload = subject.enqueue SimpleJob
      subject.failed(payload, Exception.new)
      subject.length('failed').should == 1
      subject.clear('default')
      subject.length('failed').should == 1
    end
  end

  describe 'reserve' do
    before do
      @payload = subject.enqueue SimpleJob
    end

    it 'should return next job' do
      subject.reserve(worker).id.should == @payload.id
    end

    it 'should not return an already reserved job' do
      subject.enqueue SimpleJob
      subject.reserve(worker).id.should_not == subject.reserve(worker).id
    end

    it 'should return next job in given queues' do
      subject.enqueue SimpleJob
      payload = subject.enqueue CustomQueue
      subject.enqueue SimpleJob

      worker = Qu::Worker.new('custom', 'default')

      subject.reserve(worker).id.should == payload.id
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

  describe 'failed' do
    let(:payload) { Qu::Payload.new('1', SimpleJob, []) }

    it 'should add to failure queue' do
      subject.failed(payload, Exception.new)
      subject.length('failed').should == 1
    end

    it 'should not add failed queue to the list of queues' do
      subject.failed(payload, Exception.new)
      subject.queues.should_not include('failed')
    end
  end

  describe 'completed' do
    it 'should be defined' do
      subject.respond_to?(:completed).should be_true
    end
  end

  describe 'release' do
    before do
      subject.enqueue SimpleJob
    end

    it 'should add the job back on the queue' do
      payload = subject.reserve(worker)
      subject.length(payload.queue).should == 0
      subject.release(payload)
      subject.length(payload.queue).should == 1
    end
  end

  describe 'requeue' do
    context 'with a failed job' do
      before do
        subject.enqueue(SimpleJob)
        @payload = subject.reserve(worker)
        subject.failed(@payload, Exception.new)
      end

      it 'should add the job back on the queue' do
        subject.length(@payload.queue).should == 0
        subject.requeue(@payload.id)
        subject.length(@payload.queue).should == 1

        payload = subject.reserve(worker)
        payload.should be_instance_of(Qu::Payload)
        payload.id.should == @payload.id
        payload.klass.should == @payload.klass
        payload.args.should == @payload.args
      end

      it 'should remove the job from the failed jobs' do
        subject.length('failed').should == 1
        subject.requeue(@payload.id)
        subject.length('failed').should == 0
      end

      it 'should return the job' do
        subject.requeue(@payload.id).id.should == @payload.id
      end
    end

    context 'without a failed job' do
      it 'should return false' do
        subject.requeue('1').should be_false
      end
    end
  end

  describe 'register_worker' do
    let(:worker) { Qu::Worker.new('default') }

    it 'should add worker to array of workers' do
      subject.register_worker(worker)
      subject.workers.size.should == 1
      subject.workers.first.attributes.should == worker.attributes
    end
  end

  describe 'clear_workers' do
    before { subject.register_worker Qu::Worker.new('default') }

    it 'should remove workers' do
      subject.workers.size.should == 1
      subject.clear_workers
      subject.workers.size.should == 0
    end
  end

  describe 'unregister_worker' do
    before { subject.register_worker Qu::Worker.new('default') }

    it 'should remove worker' do
      subject.unregister_worker(worker.id)
      subject.workers.size.should == 0
    end

    it 'should not remove other workers' do
      other_worker = Qu::Worker.new('other')
      subject.register_worker(other_worker)
      subject.workers.size.should == 2
      subject.unregister_worker(other_worker.id)
      subject.workers.size.should == 1
      subject.workers.first.id.should == worker.id
    end
  end

  describe 'connection=' do
    it 'should allow setting the connection' do
      connection = mock('a connection')
      subject.connection = connection
      subject.connection.should == connection
    end

    it 'should provide a default connection' do
      subject.connection.should_not be_nil
    end
  end
end
