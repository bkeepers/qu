require 'spec_helper'

describe Qu::Failure do
  describe "#report" do
    it "calls report on queue" do
      payload = Qu::Payload.new(:klass => SimpleJob)
      exception = StandardError.new
      Qu::Failure.queue.should_receive(:report).with(payload, exception)
      Qu::Failure.report(payload, exception)
    end
  end

  describe "#queue" do
    it "defaults to log" do
      described_class.queue.should eq(Qu::Failure::Log)
    end
  end

  describe "#queue=" do
    before do
      @original_queue = Qu::Failure.queue
    end

    after do
      Qu::Failure.queue = @original_queue
    end

    it "changes the queue" do
      new_queue = double("queue")
      Qu::Failure.queue = new_queue
      Qu::Failure.queue.should eq(new_queue)
    end
  end
end
