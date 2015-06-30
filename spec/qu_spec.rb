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

  it 'can load json' do
    Qu.load_json('{"foo":"bar"}').should eq({"foo" => "bar"})
  end

  it 'can dump json' do
    Qu.dump_json({"foo" => "bar"}).should eq('{"foo":"bar"}')
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

  it "can subscribe, unsubscribe and instrument events within the qu namespace" do
    events = events_for("test.qu") do
      subscribed_args = []
      regex_subscribed_args = []

      subscriber = Qu.subscribe("test") do |*args|
        subscribed_args << args
      end

      regex_subscriber = Qu.subscribe(/test/) do |*args|
        regex_subscribed_args << args
      end

      Qu.instrument("test")
      Qu.instrumenter.instrument("test") # no qu namespace, doesn't count
      Qu.unsubscribe(subscriber)
      Qu.unsubscribe(regex_subscriber)
      Qu.instrument("test") # unsubscribed, doesn't count

      subscribed_args.size.should be(1)
      regex_subscribed_args.size.should be(1)
    end

    events.size.should be(2)
  end
end
