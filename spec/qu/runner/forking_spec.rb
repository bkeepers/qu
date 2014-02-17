require 'spec_helper'
require 'qu/runner/forking'

describe Qu::Runner::Forking do

  it_should_behave_like 'a runner interface'
  it_should_behave_like 'a single job runner'

end