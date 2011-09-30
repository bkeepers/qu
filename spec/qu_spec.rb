require 'spec_helper'

describe Qu do
  %w(length queues reserve clear connection=).each do |method|
    it "should delegate #{method} to backend" do
      Qu.backend.should_receive(method).with(:arg)
      Qu.send(method, :arg)
    end
  end

  describe 'enqueue' do
    it 'should call enqueue on backend with a payload' do
      Qu.backend.should_receive(:enqueue) do |payload|
        payload.should be_instance_of(Qu::Payload)
        payload.klass.should == SimpleJob
        payload.args.should == [9,8]
      end

      Qu.enqueue SimpleJob, 9, 8
    end
  end

  describe 'configure' do
    it 'should yield Qu' do
      Qu.configure do |c|
        c.should == Qu
      end
    end
  end

  describe 'backend' do
    it 'should raise error if backend not configured' do
      Qu.backend = nil
      lambda { Qu.backend }.should raise_error
    end
  end
end
