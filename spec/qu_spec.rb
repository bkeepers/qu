require 'spec_helper'

describe Qu do
  %w(push pop complete abort size clear).each do |method|
    it "should delegate #{method} to queue" do
      Qu.queue.should_receive(method).with(:arg)
      Qu.send(method, :arg)
    end
  end

  describe 'configure' do
    it 'should yield Qu' do
      Qu.configure do |c|
        c.should == Qu
      end
    end
  end

  describe 'queue' do
    it 'should raise error if queue not configured' do
      Qu.queue = nil
      lambda { Qu.queue }.should raise_error
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
end
