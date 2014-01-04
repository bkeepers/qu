require 'spec_helper'

describe Qu::Worker do
  let(:job) { Qu::Payload.new(:id => '1', :klass => SimpleJob) }

  describe 'queues' do
    it 'should use default if none specified' do
      Qu::Worker.new.queues.should == ['default']
      Qu::Worker.new('default').queues.should == ['default']
      Qu::Worker.new(['default']).queues.should == ['default']
    end

    it 'should use specified if any' do
      Qu::Worker.new('a', 'b').queues.should == ['a', 'b']
      Qu::Worker.new(['a', 'b']).queues.should == ['a', 'b']
    end

    it 'should drop queue name whitespace' do
      Qu::Worker.new(' a ', ' b ').queues.should == ['a', 'b']
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

  describe 'start' do
    it 'sleeps for interval if no work performed' do
      begin
        original_interval = Qu.interval
        Qu.stub(:pop).and_return(nil)

        Timeout.timeout(0.1) do
          Qu::Worker.new('a', 'b', 'c').start
        end
        flunk # should never get here as it should timeout
      rescue Timeout::Error, Qu::Worker::Stop
        # all good
      ensure
        Qu.interval = original_interval
      end
    end
  end

  describe 'work' do
    context 'with job in first queue' do
      before do
        Qu.stub(:pop).and_return(job)
      end

      it 'should pop a payload and perform it' do
        Qu.should_receive(:pop).with(subject.queues.first).and_return(job)
        job.should_receive(:perform)
        subject.work
      end

      it 'returns true' do
        subject.work.should be(true)
      end
    end

    context 'with job in a middle of queue' do
      before do
        Qu.stub(:pop).and_return(nil, job)
      end

      it 'should not pop once job is found' do
        job.should_receive(:perform)
        Qu.should_not_receive(:pop).with('c')
        Qu::Worker.new('a', 'b', 'c').work.should be(true)
      end
    end

    context 'with job in last queue' do
      before do
        Qu.stub(:pop).and_return(nil, nil, nil, job)
      end

      it 'pops until job found and performs it' do
        job.should_receive(:perform)
        Qu::Worker.new('a', 'b', 'c', 'd').work
      end

      it 'returns true' do
        Qu::Worker.new('a', 'b', 'c', 'd').work.should be(true)
      end
    end

    context 'with no job in any queue' do
      before do
        Qu.stub(:pop).and_return(nil)
      end

      it 'not error' do
        expect { subject.work }.to_not raise_error
      end

      it 'pops once for each queue' do
        Qu.should_receive(:pop).with('a').once.ordered.and_return(nil)
        Qu.should_receive(:pop).with('b').once.ordered.and_return(nil)
        Qu.should_receive(:pop).with('c').once.ordered.and_return(nil)
        Qu::Worker.new('a', 'b', 'c').work
      end

      it 'returns false' do
        Qu::Worker.new('a', 'b', 'c').work.should be(false)
      end
    end
  end

  context "stopping when signal received" do
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
end
