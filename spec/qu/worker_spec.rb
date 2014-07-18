require 'spec_helper'
require 'qu/queues/memory'

describe Qu::Worker do
  let(:job) { Qu::Payload.new(:id => '1', :klass => SimpleJob) }

  subject { described_class.new(SimpleJob.queue)}

  describe 'queues' do
    it 'should raise error if no queue specified' do
      expect { described_class.new }.to raise_error(RuntimeError, "Please provide one or more queues to work on.")
    end

    it 'should use specified if any' do
      described_class.new('a', 'b').queues.should == ['a', 'b']
      described_class.new(['a', 'b']).queues.should == ['a', 'b']
      described_class.new(:a, :b).queues.should == ['a', 'b']
      described_class.new([:a, :b]).queues.should == ['a', 'b']
    end

    it 'should drop queue name whitespace' do
      described_class.new(' a ', ' b ').queues.should == ['a', 'b']
    end
  end

  describe 'id' do
    it "should default hostname and pid" do
      Socket.stub(:gethostname).and_return("foo")
      Process.stub(:pid).and_return(12345)
      worker = described_class.new('a', 'b')
      worker.id.should eq("foo:12345:a,b")
    end

    it 'should not expand star in queue names' do
      described_class.new('a', '*').id.should =~ /a,*/
    end
  end

  describe 'start' do
    it 'sleeps for interval if no work performed' do
      begin
        original_interval = Qu.interval
        Qu.stub(:pop).and_return(nil)

        Timeout.timeout(0.1) do
          described_class.new('a', 'b', 'c').start
        end
        flunk # should never get here as it should timeout
      rescue Timeout::Error, described_class::Stop
        # all good
      ensure
        Qu.interval = original_interval
      end
    end

    it 'stops worker if work loop is ever broken' do
      worker = described_class.new('a', 'b', 'c')

      begin
        Timeout.timeout(0.1) { worker.start }
        flunk # should not get here
      rescue => e
        worker.should_not be_running
      end
    end
  end

  describe 'stop' do
    context "when performing a job" do
      before do
        subject.stub(:performing?).and_return(true)
      end

      it 'raises abort with graceful shutdown disabled' do
        Qu.should_receive(:graceful_shutdown).and_return(false)
        expect { subject.stop }.to raise_exception(described_class::Abort)
      end

      it 'does not raise if graceful shutdown enabled' do
        Qu.should_receive(:graceful_shutdown).and_return(true)
        expect { subject.stop }.to_not raise_exception
      end
    end

    context "when not performing a job" do
      it 'raises stop' do
        subject.should_receive(:performing?).and_return(false)
        expect { subject.stop }.to raise_exception(described_class::Stop)
      end
    end
  end

  describe 'work' do
    context 'with job in first queue' do

      before do
        expect(Qu).to receive(:pop).with(subject.queues.first).and_return(job)
      end

      it 'should pop a payload and perform it' do
        expect(job).to receive(:perform)
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
        described_class.new('a', 'b', 'c').work.should be(true)
      end
    end

    context 'with job in last queue' do
      before do
        Qu.stub(:pop).and_return(nil, nil, nil, job)
      end

      it 'pops until job found and performs it' do
        job.should_receive(:perform)
        described_class.new('a', 'b', 'c', 'd').work
      end

      it 'returns true' do
        described_class.new('a', 'b', 'c', 'd').work.should be(true)
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
        described_class.new('a', 'b', 'c').work
      end

      it 'returns false' do
        described_class.new('a', 'b', 'c').work.should be(false)
      end
    end
  end
end
