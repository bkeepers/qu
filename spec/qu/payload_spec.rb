require 'spec_helper'

describe Qu::Payload do
  class MyJob
    @queue = :custom
  end

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

    it 'should get queue from instance variable' do
      Qu::Payload.new(:klass => MyJob).queue.should == 'custom'
    end
  end

  describe 'klass' do
    it 'should constantize string' do
      Qu::Payload.new(:klass => 'MyJob').klass.should == MyJob
    end

    it 'should find namespaced class' do
      Qu::Payload.new(:klass => 'Qu::Payload').klass.should == Qu::Payload
    end
  end

  describe 'perform' do
    subject { Qu::Payload.new(:klass => SimpleJob) }

    it 'should call .perform on class with args' do
      subject.args = ['a', 'b']
      SimpleJob.should_receive(:perform).with('a', 'b')
      subject.perform
    end

    it 'should call completed on backend' do
      Qu.backend.should_receive(:completed)
      subject.perform
    end

    context 'when being aborted' do
      before do
        SimpleJob.stub(:perform).and_raise(Qu::Worker::Abort)
      end

      it 'should release the job and re-raise the error' do
        Qu.backend.should_receive(:release).with(subject)
        lambda { subject.perform }.should raise_error(Qu::Worker::Abort)
      end
    end

    context 'when the job raises an error' do
      let(:error) { Exception.new("Some kind of error") }

      before do
        SimpleJob.stub!(:perform).and_raise(error)
      end

      it 'should call failed on backend' do
        Qu.backend.should_receive(:failed).with(subject, error)
        subject.perform
      end

      it 'should not call completed on backend' do
        Qu.backend.should_not_receive(:completed)
        subject.perform
      end

      it 'should call create on failure backend' do
        Qu.failure = mock('a failure backend')
        Qu.failure.should_receive(:create).with(subject, error)
        subject.perform
      end
    end

  end
end
