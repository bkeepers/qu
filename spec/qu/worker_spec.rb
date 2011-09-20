require 'spec_helper'

describe Qu::Worker do
  let(:job) { Qu::Job.new('1', SimpleJob, []) }

  describe 'queues' do
    before do
      Qu.stub!(:queues).and_return(%w(c a b))
    end

    it 'should use all queues from backend with an asterisk' do
      Qu::Worker.new('*').queues.should == %w(a b c)
    end

    it 'should append other queues with an asterisk' do
      Qu::Worker.new('b', '*').queues.should == %w(b a c)
    end

    it 'should properly handle queues passed as an array to the initializer' do
      Qu::Worker.new(%w(b *)).queues.should == %w(b a c)
    end
  end

  describe 'work' do
    before do
      Qu.stub!(:reserve).and_return(job)
    end

    it 'should reserve a job' do
      Qu.should_receive(:reserve).with(subject).and_return(job)
      subject.work
    end

    it 'should perform the job' do
      job.should_receive(:perform)
      subject.work
    end
  end

  describe 'work_off' do
    it 'should work all jobs off the queue' do
      Qu.should_receive(:reserve).exactly(4).times.with(subject, :block => false).and_return(job, job, job, nil)
      subject.work_off
    end
  end

  describe 'running?' do
    it 'should default to false' do
      subject.running?.should be_false
    end
  end
end
