require 'spec_helper'
require 'qu/queues/memory'

describe Qu::Queues::Memory do
  it_should_behave_like 'a queue'
  it_should_behave_like 'a queue interface'
end