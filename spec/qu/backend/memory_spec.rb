require 'spec_helper'
require 'qu/backend/memory'

describe Qu::Backend::Memory do
  it_should_behave_like 'a backend'
  it_should_behave_like 'a backend interface'
end