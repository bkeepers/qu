require 'spec_helper'

describe Qu::Payload do
  it 'should default id to nil' do
    Qu::Payload.new.id.should == nil
  end

  it 'should allow id to be set' do
    Qu::Payload.new(:id => 5).id.should == 5
  end

  it 'should allow getting and setting arbitrary attributes' do
    payload = Qu::Payload.new
    payload.foo = :bar
    payload.foo.should eq(:bar)
  end

  describe 'queue' do
    it 'should require the klass attribute' do
      expect {
        Qu::Payload.new.queue
      }.to raise_error(RuntimeError, "Please set the klass for the payload.")
    end

    it 'should get queue from klass' do
      Qu::Payload.new(:klass => SimpleJob).queue.should eq(Qu.queues[SimpleJob.queue])
    end
  end

  describe 'klass' do
    it 'should constantize string' do
      Qu::Payload.new(:klass => 'SimpleJob').klass.should == SimpleJob
    end

    it 'should find namespaced class' do
      Qu::Payload.new(:klass => 'Qu::Payload').klass.should == Qu::Payload
    end
  end

  describe 'attributes' do
    subject { Qu::Payload.new(:klass => SimpleJob, :args => ['test'], :id => 1) }

    it 'returns hash of attributes' do
      subject.attributes.should eq({
        :klass => 'SimpleJob',
        :args => ['test'],
        :id => 1,
      })
    end
  end

  describe 'job' do
    subject { Qu::Payload.new(:klass => SimpleJob) }

    it 'should load the job' do
      SimpleJob.should_receive(:load).with(subject)
      subject.job
    end

    it 'should return the job' do
      subject.job.should be_instance_of(SimpleJob)
    end
  end

  describe 'perform' do
    subject { Qu::Payload.new(:klass => SimpleJob) }

    it 'should call perform on job' do
      subject.job.should_receive(:perform)
      subject.perform
    end

    it 'should run perform hooks' do
      subject.job.stub(:run_hook).and_yield
      subject.job.should_receive(:run_hook).with(:perform)
      subject.perform
    end

    it 'should call complete on queue' do
      subject.queue.should_receive(:complete)
      subject.perform
    end

    it 'should run complete hooks' do
      subject.job.stub(:run_hook).and_yield
      subject.job.should_receive(:run_hook).with(:complete)
      subject.perform
    end

    context 'when being aborted' do
      before do
        SimpleJob.any_instance.stub(:perform).and_raise(Qu::Worker::Abort)
      end

      it 'should abort the job and re-raise the error' do
        subject.queue.should_receive(:abort).with(subject)
        lambda { subject.perform }.should raise_error(Qu::Worker::Abort)
      end

      it 'should not call complete' do
        subject.queue.should_not_receive(:complete)
        lambda { subject.perform }.should raise_error(Qu::Worker::Abort)
      end

      it 'should run abort hook' do
        subject.job.stub(:run_hook).and_yield
        subject.job.should_receive(:run_hook).with(:abort)
        lambda { subject.perform }.should raise_error(Qu::Worker::Abort)
      end
    end

    context 'when the job raises an error' do
      let(:error) { StandardError.new("Some kind of error") }

      before do
        subject.job.stub(:perform).and_raise(error)
      end

      it 'should not call complete' do
        subject.queue.should_not_receive(:complete)
        subject.perform
      end

      it 'should call fail' do
        subject.queue.should_receive(:fail).with(subject)
        subject.perform
      end

      it 'should run fail hook' do
        subject.job.stub(:run_hook).and_yield
        subject.job.should_receive(:run_hook).with(:fail, error)
        subject.perform
      end

      it 'should call report for failure queue' do
        Qu::Failure.should_receive(:report).with(subject, error)
        subject.perform
      end
    end
  end

  describe "push" do
    subject { Qu::Payload.new(:klass => SimpleJob) }

    it "pushes payload to queue" do
      subject.queue.should_receive(:push).with(subject)
      subject.push
    end

    it "sets pushed_at" do
      subject.pushed_at.should be_nil
      subject.push
      subject.pushed_at.should be_instance_of(Time)
    end
  end
end
