require 'spec_helper'

describe Qu::Job do
  %w(push perform complete abort fail).each do |hook|
    it "should define hooks for #{hooks}" do
      Qu::Job.should respond_to("before_#{hook}")
      Qu::Job.should respond_to("around_#{hook}")
      Qu::Job.should respond_to("after_#{hook}")
    end
  end

  describe '.queue' do
    it 'should allow setting the queue name' do
      begin
        original = SimpleJob.queue
        SimpleJob.queue(:foobar)
        SimpleJob.queue.should eq(:foobar)
      ensure
        SimpleJob.queue(original)
      end
    end
  end

  describe '.load' do
    let(:payload) { Qu::Payload.new(:klass => 'SimpleJob') }

    it 'should return an instance' do
      SimpleJob.load(payload).should be_instance_of(SimpleJob)
    end

    it 'should initialize with args' do
      payload.args = [:foo]

      job_class = Class.new(Qu::Job) do
        def initialize(arg)
          @arg = arg
        end
      end
      job_class.load(payload).instance_variable_get(:@arg).should == :foo
    end

    it 'should assign payload before initializing' do
      job_class = Class.new(Qu::Job) do
        def initialize
          payload.foo = :bar
        end
      end

      job = job_class.load(payload)
      job.payload.should eq(payload)
      payload.foo.should == :bar
    end
  end

  describe 'create' do
    it 'should call push with a payload' do
      Qu.queues[SimpleJob.queue].should_receive(:push) do |payload|
        payload.queue.should eq(Qu.queues[SimpleJob.queue])
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
      Qu.queues[SimpleJob.queue].should_not_receive(:push)

      SimpleJob.create(9)
    end
  end

  it 'delegates logger to Qu.logger' do
    SimpleJob.new.logger.should be(Qu.logger)
  end
end
