require 'spec_helper'

describe Qu do
  %w(size queues pop clear connection=).each do |method|
    it "should delegate #{method} to backend" do
      Qu.backend.should_receive(method).with(:arg)
      Qu.send(method, :arg)
    end
  end

  describe 'enqueue' do
    it 'should call create on backend the class' do
      SimpleJob.should_receive(:create).with(9, 8)
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
