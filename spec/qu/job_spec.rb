require 'spec_helper'

describe Qu::Job do
  class MyJob
    @queue = :custom
  end

  describe 'queue' do
    it 'should default to "default"' do
      Qu::Job.new('1', SimpleJob, []).queue.should == 'default'
    end

    it 'should get queue from job instance variable' do
      Qu::Job.new('1', MyJob, []).queue.should == 'custom'
    end
  end

  describe 'klass' do
    it 'should constantize string' do
      Qu::Job.new('1', 'MyJob', []).klass.should == MyJob
    end

    it 'should find namespaced jobs' do
      Qu::Job.new('1', 'Qu::Job', []).klass.should == Qu::Job
    end
  end

  describe 'perform' do
    it 'should call .perform on job class with args' do
      SimpleJob.should_receive(:perform).with('a', 'b')
      Qu::Job.new('1', SimpleJob, ['a', 'b']).perform
    end
  end
end
