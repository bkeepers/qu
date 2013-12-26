require 'spec_helper'

describe Qu::Payload do
  it 'should default id to nil' do
    Qu::Payload.new.id.should == nil
  end

  it 'should allow id to be set' do
    Qu::Payload.new(:id => 5).id.should == 5
  end

  describe 'queue' do
    it 'should default to "default"' do
      Qu::Payload.new.queue.should == 'default'
    end

    it 'should get queue from klass' do
      Qu::Payload.new(:klass => CustomQueue).queue.should == 'custom'
    end
  end

  describe 'klass' do
    it 'should constantize string' do
      Qu::Payload.new(:klass => 'CustomQueue').klass.should == CustomQueue
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

    it 'should call completed on backend' do
      Qu.backend.should_receive(:completed)
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
        Qu.backend.should_receive(:abort).with(subject)
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
        SimpleJob.any_instance.stub(:perform).and_raise(error)
      end

      it 'should not call completed on backend' do
        Qu.backend.should_not_receive(:completed)
        subject.perform
      end

      it 'should call create on failure backend' do
        Qu.failure = double('a failure backend')
        Qu.failure.should_receive(:create).with(subject, error)
        subject.perform
      end

      it 'should run failure hook with exception' do
        subject.job.stub(:run_hook).and_yield
        subject.job.should_receive(:run_hook).with(:failure, error)
        subject.perform
      end

    end
  end
end
