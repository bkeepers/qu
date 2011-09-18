require 'spec_helper'

describe Qu do
  describe 'enqueue' do
    it 'should call enqueue on the backend with a job' do
      Qu.backend.should_receive(:enqueue).with(SimpleJob, 'a', 'b')
      Qu.enqueue SimpleJob, 'a', 'b'
    end
  end
end
