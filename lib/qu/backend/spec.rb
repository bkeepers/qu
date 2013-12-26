unless defined?(SystemTimer)
  require 'timeout'
  SystemTimer = Timeout
end

class SimpleJob < Qu::Job
end

class CustomQueue < Qu::Job
  queue :custom
end

shared_examples_for 'a backend' do |options|
  options ||= {}
  services = Array(options[:services]).inject({}) { |hash, service|
    hash[service] = service_running?(service)
    hash
  }

  down_services = services.select { |k, v| !v }.keys

  if down_services.empty?
    let(:worker) { Qu::Worker.new('default') }
    let(:payload) { Qu::Payload.new(:klass => SimpleJob) }

    before(:all) do
      Qu.backend = described_class.new
    end

    before do
      subject.clear
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
        subject.enqueue(payload)
        payload.queue.should == 'default'
        subject.length(payload.queue).should == 1
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
    end

    describe 'reserve' do
      it 'should return next job' do
        subject.enqueue(payload)
        subject.reserve(worker).id.should == payload.id
      end

      it 'should not return an already reserved job' do
        subject.enqueue(payload)
        subject.enqueue(payload.dup)
        subject.reserve(worker).id.should_not == subject.reserve(worker).id
      end

      it 'should return next job based on queue order for worker' do
        subject.enqueue(payload)
        custom = subject.enqueue(Qu::Payload.new(:klass => CustomQueue))
        subject.enqueue(payload.dup)

        worker = Qu::Worker.new('custom', 'default')

        subject.reserve(worker).id.should == custom.id
      end

      it 'should not return job from different queue' do
        subject.enqueue(payload)
        worker = Qu::Worker.new('video')
        timeout { subject.reserve(worker) }.should be_nil
      end

      it 'should block by default if no jobs available' do
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
        payload.args = ['a', 'b']
        subject.enqueue(payload)
        subject.reserve(worker).args.should == ['a', 'b']
      end

      it 'should properly persist a hash argument' do
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
        reserved_payload = subject.reserve(worker)
        reserved_payload.id.should == payload.id
        subject.length(payload.queue).should == 0
        subject.release(reserved_payload)
        subject.length(payload.queue).should == 1
      end
    end

    describe 'connection=' do
      it 'should allow setting the connection' do
        connection = double('a connection')
        subject.connection = connection
        subject.connection.should == connection
      end

      it 'should provide a default connection' do
        subject.connection.should_not be_nil
      end
    end
  else
    puts "Skipping #{described_class}. Required services are not running (#{down_services.join(', ')})."
  end
end
