unless defined?(SystemTimer)
  require 'timeout'
  SystemTimer = Timeout
end

class SimpleJob
  def self.perform
  end
end

class CustomQueue
  @queue = :custom
end

shared_examples_for 'a backend' do
  let(:worker) { Qu::Worker.new('default') }
  let(:payload) { Qu::Payload.new(:klass => SimpleJob) }

  before(:all) do
    Qu.backend = described_class.new
  end

  before do
    subject.clear
    subject.clear_workers
  end

  describe 'enqueue' do
    it 'should return a payload' do
      subject.enqueue(payload).should be_instance_of(Qu::Payload)
    end

    it 'should set the payload id' do
      subject.enqueue(payload)
      payload.id.should_not be_nil
    end

    it 'should add a job to the queue' do
      length = subject.length(payload.queue)
      subject.enqueue(payload)
      payload.queue.should == 'default'
      subject.length(payload.queue).should == length + 1
    end

    it 'should add queue to list of queues' do
      subject.queues.should == []
      subject.enqueue(payload)
      subject.queues.should == [payload.queue]
    end

    it 'should assign a different job id for the same job enqueue multiple times' do
      subject.enqueue(payload).id.should_not == subject.enqueue(payload).id
    end
  end

  describe 'length' do
    it 'should use the default queue by default' do
      subject.length.should == 0
      subject.enqueue(payload)
      subject.length.should == 1
    end
  end

  describe 'clear' do
    it 'should clear jobs for given queue' do
      subject.enqueue payload
      subject.length(payload.queue).should == 1
      subject.clear(payload.queue)
      subject.length(payload.queue).should == 0
      subject.queues.should_not include(payload.queue)
    end

    it 'should not clear jobs for a different queue' do
      subject.enqueue(payload)
      subject.clear('other')
      subject.length(payload.queue).should == 1
    end

    it 'should clear all queues without any args' do
      subject.enqueue(payload).queue.should == 'default'
      subject.enqueue(Qu::Payload.new(:klass => CustomQueue)).queue.should == 'custom'
      subject.length('default').should == 1
      subject.length('custom').should == 1
      subject.clear
      subject.length('default').should == 0
      subject.length('custom').should == 0
    end

    it 'should keep failed jobs' do
      subject.enqueue(payload)
      subject.failed(payload, Exception.new)
      subject.length('default').should == 1
      subject.clear
      subject.jobs('default').count == 1
    end
  end

  describe 'reserve' do
    before do
      subject.enqueue(payload)
    end

    it 'should return next job' do
      subject.enqueue(payload.dup)
      subject.enqueue(payload.dup)
      subject.enqueue(payload.dup)
      subject.reserve(worker).id.should == payload.id
    end

    it 'should not return an already reserved job' do
      subject.enqueue(payload.dup)
      subject.reserve(worker).id.should_not == subject.reserve(worker).id
    end

    it 'should return next job in given queues' do
      subject.enqueue(payload.dup)
      custom = subject.enqueue(Qu::Payload.new(:klass => CustomQueue))
      subject.enqueue(payload.dup)

      worker = Qu::Worker.new('custom', 'default')

      subject.reserve(worker).id.should == custom.id
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

    it 'should properly persist args' do
      subject.clear
      payload.args = ['a', 'b']
      subject.enqueue(payload)
      subject.reserve(worker).args.should == ['a', 'b']
    end

    it 'should properly persist a hash argument' do
      subject.clear
      payload.args = [{:a => 1, :b => 2}]
      subject.enqueue(payload)
      subject.reserve(worker).args.should == [{'a' => 1, 'b' => 2}]
    end

    def timeout(count = 0.1, &block)
      SystemTimer.timeout(count, &block)
    rescue Timeout::Error
      nil
    end
  end

  describe 'failed' do
    let(:payload) { Qu::Payload.new(:id => '1', :klass => SimpleJob) }

    it 'should be kept in queue' do
      subject.enqueue(payload)
      subject.failed(payload, Exception.new)
      subject.jobs('default').count.should == 1
    end

    it 'should not be counted by length' do
      subject.enqueue(payload)
      subject.failed(payload, Exception.new)
      length('default').count.should == 0
    end

    it 'should have a failed state' do
      payload = subject.enqueue(payload)
      subject.failed(payload, Exception.new)
      subject.jobs('default').find_one(:_id => payload.id).state.should == 'die'
    end
  end

  describe 'completed' do
    it 'should be defined' do
      subject.respond_to?(:completed).should be_true
    end
  end

  describe 'release' do
    before do
      subject.enqueue(payload)
    end

    it 'should add the job back on the queue' do
      subject.reserve(worker).id.should == payload.id
      subject.length(payload.queue).should == 0
      subject.release(payload)
      subject.length(payload.queue).should == 1
    end
  end

  describe 'requeue' do
    context 'with a failed job' do
      before do
        subject.enqueue(payload)
        subject.reserve(worker).id.should == payload.id
        subject.failed(payload, Exception.new)
      end

      it 'should add the job back on the queue' do
        subject.length(payload.queue).should == 0
        subject.requeue(payload.queue, payload.id)
        subject.length(payload.queue).should == 1

        p = subject.reserve(worker)
        p.should be_instance_of(Qu::Payload)
        p.id.should == payload.id
        p.klass.should == payload.klass
        p.args.should == payload.args
      end

      it 'should return the job' do
        subject.requeue(payload.queue, payload.id).id.should == payload.id
      end
    end

    context 'without a failed job' do
      it 'should return false' do
        subject.requeue('default', '1').should be_false
      end
    end
  end

  describe 'register_worker' do
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
    before { subject.register_worker(worker) }

    it 'should remove worker' do
      subject.unregister_worker(worker)
      subject.workers.size.should == 0
    end

    it 'should not remove other workers' do
      other_worker = Qu::Worker.new('other')
      subject.register_worker(other_worker)
      subject.workers.size.should == 2
      subject.unregister_worker(other_worker)
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
