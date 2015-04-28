require 'spec_helper'

describe Qu do
  describe 'configure' do
    it 'should yield Qu' do
      Qu.configure do |c|
        c.should == Qu
      end
    end
  end

  describe 'interval' do
    it 'defaults to 5' do
      Qu.interval.should be(5)
    end
  end

  describe 'interval=' do
    before do
      @original_interval = Qu.interval
    end

    after do
      Qu.interval = @original_interval
    end

    it 'updates interval' do
      Qu.interval = 1
      Qu.interval.should be(1)
    end
  end

  [
    :instrumenter,
    :instrumenter=,
  ].each do |method_name|
    it "responds to #{method_name}" do
      Qu.should respond_to(method_name)
    end
  end

  describe "#register" do
    it "sets instance to name in queues hash" do
      Qu.register :foo, Qu::Queues::Memory.new
      Qu.queues[:foo].should be_instance_of(Qu::Queues::Instrumented)
      Qu.queues[:foo].queue.should be_instance_of(Qu::Queues::Memory)
      Qu.queues[:foo].name.should eq(:foo)
    end
  end
end
