require 'spec_helper'

describe Qu::Failure do
  describe "#create" do
    it "calls create on backend" do
      payload = Qu::Payload.new(:klass => SimpleJob)
      exception = StandardError.new
      Qu::Failure.backend.should_receive(:create).with(payload, exception)
      Qu::Failure.create(payload, exception)
    end
  end

  describe "#backend" do
    it "defaults to log" do
      described_class.backend.should eq(Qu::Failure::Log)
    end
  end

  describe "#backend=" do
    before do
      @original_backend = Qu::Failure.backend
    end

    after do
      Qu::Failure.backend = @original_backend
    end

    it "changes the backend" do
      new_backend = double("backend")
      Qu::Failure.backend = new_backend
      Qu::Failure.backend.should eq(new_backend)
    end
  end
end
