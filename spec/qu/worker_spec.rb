require 'spec_helper'

describe Qu::Worker do
  let(:job) { Qu::Payload.new(:id => '1', :klass => SimpleJob) }

  describe 'queues' do
    it 'should use default if none specified' do
      Qu::Worker.new.queues.should == ['default']
      Qu::Worker.new('default').queues.should == ['default']
      Qu::Worker.new(['default']).queues.should == ['default']
    end
  end

  describe 'work' do
    context "with job" do
      before do
        Qu.stub(:pop).and_return(job)
      end

      it 'should pop a job' do
        Qu.should_receive(:pop).with(subject.queues.first).and_return(job)
        subject.work
      end

      it 'should perform the job' do
        job.should_receive(:perform)
        subject.work
      end
    end

    context "with no job" do
      before do
        Qu.stub(:pop).and_return(nil)
      end

      it 'not error' do
        expect { subject.work }.to_not raise_error
      end
    end
  end

  describe "stopping when signal received" do
    shared_context "graceful shutdown" do
      before do
        @original_shutdown = Qu.graceful_shutdown
        Qu.graceful_shutdown = true
      end

      after do
        Qu.graceful_shutdown = @original_shutdown
      end
    end

    shared_context "no graceful shutdown" do
      before do
        @original_shutdown = Qu.graceful_shutdown
        Qu.graceful_shutdown = false
      end

      after do
        Qu.graceful_shutdown = @original_shutdown
      end
    end

    before do
      job.stub(:perform) do
        Process.kill('SIGTERM', $$)
        sleep(0.01)
      end
    end

    def send_terminate_signal
      Thread.new do
        sleep(0.01)
        Process.kill('SIGTERM', $$)
      end
    end

    context "with graceful shutdown and backend stuck popping" do
      include_context "graceful shutdown"

      it "raises stop" do
        Qu.stub(:pop) { sleep }
        send_terminate_signal
        expect { subject.start }.to raise_exception(Qu::Worker::Stop)
      end
    end

    context "with graceful shutdown and job performing" do
      include_context "graceful shutdown"

      it 'waits for the job to finish and shuts down' do
        Qu.stub(:pop).and_return(job)
        subject.stub(:performing?).and_return(true)
        expect { subject.start }.to_not raise_exception
      end
    end

    context "with no graceful shutdown and no job performing" do
      include_context "no graceful shutdown"

      it "raises stop" do
        send_terminate_signal
        expect { subject.start }.to raise_exception(Qu::Worker::Stop)
      end
    end

    context "with no graceful shutdown and job performing" do
      include_context "no graceful shutdown"

      it "raises abort" do
        subject.stub(:performing?).and_return(true)
        send_terminate_signal
        expect { subject.start }.to raise_exception(Qu::Worker::Abort)
      end
    end
  end

  describe 'id' do
    it 'should return hostname, pid, and queues' do
      worker = Qu::Worker.new('a', 'b', :hostname => 'quspec', :pid => 123)
      worker.id.should == 'quspec:123:a,b'
    end

    it "should default hostname and pid" do
      worker = Qu::Worker.new('a', 'b')
      worker.id.should eq("#{Socket.gethostname}:#{Process.pid}:a,b")
    end

    it 'should not expand star in queue names' do
      Qu::Worker.new('a', '*').id.should =~ /a,*/
    end
  end

  describe 'attributes' do
    let(:attrs) do
      {'hostname' => 'omgbbq', 'pid' => 987, 'queues' => ['a', '*']}
    end

    it 'should return hash of attributes' do
      Qu::Worker.new(attrs).attributes.should == attrs
    end
  end
end
