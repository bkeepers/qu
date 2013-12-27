require 'spec_helper'
require 'qu-immediate'

describe Qu::Backend::Immediate do
  let(:payload) { Qu::Payload.new(:klass => SimpleJob) }

  before(:all) do
    Qu.backend = described_class.new
  end

  it 'performs immediately' do
    payload.should_receive(:perform)
    subject.push(payload)
  end
end
