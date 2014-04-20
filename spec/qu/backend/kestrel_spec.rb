require 'spec_helper'
require 'qu/backend/kestrel'

describe Qu::Backend::Kestrel do
  if Qu::Specs.perform?(described_class, :kestrel)
    it_should_behave_like 'a backend'
    it_should_behave_like 'a backend interface'
  end
end
