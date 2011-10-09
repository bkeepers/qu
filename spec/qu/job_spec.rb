require 'spec_helper'

describe Qu::Job do
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
end
