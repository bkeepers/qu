require 'spec_helper'
require 'qu-redis'

describe Qu::Backend::Redis do
  it_should_behave_like 'a backend'
end
