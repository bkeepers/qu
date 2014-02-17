require 'spec_helper'
require 'qu/runner/direct'

describe Qu::Runner::Direct do
  it_should_behave_like 'a runner interface'
  it_should_behave_like 'a single job runner'
end
