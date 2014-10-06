require 'spec_helper'

class SimpleBatchJob < Qu::BatchJob
end

class CustomBatchJob < Qu::BatchJob
  queue 'custom'
  batch_size 10
end

describe Qu::BatchJob do
  %w(push perform complete abort fail).each do |hook|
    it "should define hooks for #{hooks}" do
      Qu::BatchJob.should respond_to("before_#{hook}")
      Qu::BatchJob.should respond_to("around_#{hook}")
      Qu::BatchJob.should respond_to("after_#{hook}")
    end
  end

  describe '.queue' do
    it 'should allow setting the queue name' do
      CustomBatchJob.queue.should == 'custom'
    end

    it 'should default to default' do
      SimpleBatchJob.queue.should == 'default'
    end
  end

  describe '.load' do
    let(:payload) { Qu::Payload.new(:klass => 'SimpleBatchJob')}

    it 'should return an instance' do
      SimpleBatchJob.load(payload).should be_instance_of(SimpleBatchJob)
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
    it 'should call push with a payload' do
      Qu.should_receive(:push) do |payload|
        payload.queue.should eq('default')
        payload.should be_instance_of(Qu::Payload)
        payload.klass.should == SimpleBatchJob
        payload.args.should == [9]
      end

      SimpleBatchJob.create(9)
    end

    it 'should run push hoook' do
      SimpleBatchJob.any_instance.should_receive(:run_hook).with(:push).and_yield
      SimpleBatchJob.create(9)
    end

    it 'should not push job if hook halts' do
      SimpleBatchJob.any_instance.stub(:run_hook)
      Qu.should_not_receive(:push)

      SimpleBatchJob.create(9)
    end
  end

  it 'delegates logger to Qu.logger' do
    SimpleBatchJob.new.logger.should be(Qu.logger)
  end

  it 'responds to batch_job? with true' do
    SimpleBatchJob.batch_job?.should == true
  end

  describe 'batch' do
    let(:job) { SimpleBatchJob.new }
    let(:custom_job) { CustomBatchJob.new }

    describe '.batch_size' do
      it 'returns a default batch size' do
        SimpleBatchJob.batch_size.should == 1
      end

      it 'configures the batch size' do
        CustomBatchJob.batch_size.should == 10
      end
    end

    describe '.full?' do
      it 'returns false when batch is not full' do
        job.full?.should == false
      end

      it 'returns true when batch is full' do
        job.append(1)
        job.full?.should == true
      end

      it 'returns false when custom-sized batch is partially full' do
        custom_job.append(1)
        custom_job.full?.should == false
      end

      it 'returns true when custom-sized batch is full' do
        custom_job.append(*[1]*10)
        custom_job.full?.should == true
      end
    end

    describe '.append' do
      it 'adds a payload to the batch' do
        job.append(1)
        job.batch.should == [1]
      end

      it 'adds multiple payloads to the batch' do
        job.append(1,2)
        job.append(3,4)
        job.batch.should == [1,2,3,4]
      end

      it 'adds a payload via <<' do
        job << 1
        job.batch.should == [1]
      end
    end

    describe '.each' do
      it 'yields each set of payload args' do
        job << Qu::Payload.new(:klass => job.class, :args => [1])
        job_args = []
        job.each do |*args|
          job_args << args
        end
        job_args.should == [[1]]
      end

      it 'yields each set of payload args in custom-sized batch' do
        5.times do |i|
          custom_job.append(Qu::Payload.new(:klass => custom_job.class, :args => [i]))
        end
        job_args = []
        custom_job.each do |*args|
          job_args << args
        end
        job_args.should == [[0],[1],[2],[3],[4]]
      end

      it 'supports enumerable methods' do
        5.times do |i|
          custom_job.append(Qu::Payload.new(:klass => custom_job.class, :args => [i, 'a']))
        end
        job_args = custom_job.collect.to_a.should == [[0, 'a'], [1, 'a'], [2, 'a'], [3, 'a'], [4, 'a']]
      end
    end

    describe '.each_payload' do
      it 'yields each payload' do
        job_payload = Qu::Payload.new(:klass => job.class, :args => [1])
        job << job_payload
        payloads = []
        job.each_payload do |payload|
          payloads << payload
        end
        payloads.should == [job_payload]
      end
    end
  end
end
