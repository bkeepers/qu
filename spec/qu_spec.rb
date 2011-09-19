require 'spec_helper'

describe Qu do
  before do
    Qu.backend = mock('a backend')
  end

  %w(enqueue length queues reserve clear).each do |method|
    it "should delegate #{method} to backend" do
      Qu.backend.should_receive(method).with(:arg)
      Qu.send(method, :arg)
    end
  end


  describe 'enqueue' do
    it 'should call enqueue on the backend with a job' do
      Qu.backend.should_receive(:enqueue).with(SimpleJob, 'a', 'b')
      Qu.enqueue SimpleJob, 'a', 'b'
    end
  end
end
