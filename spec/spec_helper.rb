require 'bundler'
Bundler.require :test
require 'qu'
require 'qu/backend/spec'

RSpec.configure do |config|
  config.before do
    Qu.backend = mock('a backend', :reserve => nil, :failed => nil, :completed => nil,
      :register_worker => nil, :unregister_worker => nil)
    Qu.failure = nil
  end
end

Qu.logger = Logger.new('/dev/null')