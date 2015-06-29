require 'spec_helper'

describe Qu::Failure do
  describe "#report" do
    it "calls report on reporter" do
      payload = Qu::Payload.new(:klass => SimpleJob)
      exception = StandardError.new
      Qu::Failure.reporter.should_receive(:report).with(payload, exception)
      Qu::Failure.report(payload, exception)
    end
  end

  describe "#reporter" do
    it "defaults to log" do
      described_class.reporter.should eq(Qu::Failure::Log)
    end
  end

  describe "#reporter=" do
    before do
      @original_queue = Qu::Failure.reporter
    end

    after do
      Qu::Failure.reporter = @original_queue
    end

    it "changes the reporter" do
      new_reporter = double("reporter")
      Qu::Failure.reporter = new_reporter
      Qu::Failure.reporter.should eq(new_reporter)
    end
  end
end
