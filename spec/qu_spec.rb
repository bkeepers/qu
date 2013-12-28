require 'spec_helper'

describe Qu do
  %w(push pop complete abort size clear).each do |method|
    it "should delegate #{method} to backend" do
      Qu.backend.should_receive(method).with(:arg)
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

  describe 'backend' do
    it 'should raise error if backend not configured' do
      Qu.backend = nil
      lambda { Qu.backend }.should raise_error
    end
  end

  [
    :instrument,
    :instrumenter,
    :instrumenter=,
  ].each do |method_name|
    it "responds to #{method_name}" do
      Qu.should respond_to(method_name)
    end
  end
end
