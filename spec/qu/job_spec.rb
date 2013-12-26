require 'spec_helper'

describe Qu::Job do
  %w(push perform complete failure release).each do |hook|
    it "should define hooks for #{hooks}" do
      Qu::Job.should respond_to("before_#{hook}")
      Qu::Job.should respond_to("around_#{hook}")
      Qu::Job.should respond_to("after_#{hook}")
    end
  end

  describe '.queue' do
    it 'should allow setting the queue name' do
      CustomQueue.queue.should == 'custom'
    end

    it 'should default to default' do
      SimpleJob.queue.should == 'default'
    end
  end

  describe '.load' do
    let(:payload) { Qu::Payload.new(:klass => 'SimpleJob')}

    it 'should return an instance' do
      SimpleJob.load(payload).should be_instance_of(SimpleJob)
    end

    it 'should initialize with args' do
      payload.args = [:foo]

      c = Class.new(Qu::Job) do
        def initialize(arg)
          @arg = arg
        end
      end
      c.load(payload).instance_variable_get(:@arg).should == :foo
    end

    it 'should assign payload before initializing' do
      c = Class.new(Qu::Job) do
        def initialize
          payload.foo = :bar
        end
      end

      job = c.load(payload)
      job.payload.should == payload
      payload.foo.should == :bar
    end
  end

  describe 'create' do
    it 'should call push on backend with a payload' do
      Qu.backend.should_receive(:push) do |payload|
        payload.should be_instance_of(Qu::Payload)
        payload.klass.should == SimpleJob
        payload.args.should == [9]
      end

      SimpleJob.create(9)
    end

    it 'should run push hoook' do
      SimpleJob.any_instance.should_receive(:run_hook).with(:push).and_yield
      SimpleJob.create(9)
    end

    it 'should not push job if hook halts' do
      SimpleJob.any_instance.stub(:run_hook)
      Qu.backend.should_not_receive(:push)

      SimpleJob.create(9)
    end
  end
end
