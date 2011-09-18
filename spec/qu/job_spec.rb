require 'spec_helper'

describe Qu::Job do
  class MyJob < Qu::Job.with(:arg)
    queue :custom
  end

  describe '.queue' do
    it 'should default to "default"' do
      Qu::Job.queue.should == 'default'
    end

    it 'should allow setting a queue' do
      MyJob.queue.should == 'custom'
    end
  end

  describe '.with' do
    subject { Qu::Job.with(:arg1, :arg2) }

    it 'should create a subclass of job' do
      subject.should < Qu::Job
    end

    it 'should define attr readers for args' do
      lambda { subject.instance_method('arg1') }.should_not raise_error(NameError)
      lambda { subject.instance_method('arg2') }.should_not raise_error(NameError)
    end

    it 'should define an initializer for the args' do
      subject.instance_method('initialize').arity.should == 2
      subject.new('a', 'b').arg1.should == 'a'
    end
  end

  describe '.load' do
    it 'should initialize a job of the given class' do
      Qu::Job.load('1', 'MyJob', [1]).should be_instance_of(MyJob)
    end

    it 'should find namespaced jobs' do
      Qu::Job.load('1', 'Qu::Job', []).should be_instance_of(Qu::Job)
    end

    it 'should set job id' do
      Qu::Job.load('987', 'MyJob', [1]).id.should == '987'
    end

    it 'should initialize with with args' do
      Qu::Job.load('1', 'MyJob', ['a']).arg.should == 'a'
    end
  end

  # describe 'encode' do
  #   it 'should json encode the class and args' do
  #     MultiJson.decode(subject.encode).should == {'klass' => 'SimpleJob', 'args' => [1, 2]}
  #   end
  # end
  #
  # describe 'attributes' do
  #   it 'should return a hash of attributes' do
  #     subject.attributes.should == {'klass' => 'SimpleJob', 'args' => [1, 2]}
  #   end
  # end
  #
  # describe 'perform' do
  #   it 'should call .perform on the class' do
  #     SimpleJob.should_receive(:perform).with(1, 2)
  #     subject.perform
  #   end
  # end
end
