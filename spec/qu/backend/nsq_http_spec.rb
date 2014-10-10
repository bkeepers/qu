require 'spec_helper'
require 'qu-nsq-http'

describe Qu::Backend::NSQHTTP do
  if Qu::Specs.perform?(described_class, :nsq)
    it_should_behave_like 'a pushing backend'
    it_should_behave_like 'a backend interface'
  end
end
