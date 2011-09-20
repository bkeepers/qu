require 'bundler'
Bundler.require :default, :test
require 'qu'
require 'qu/backend/spec'

RSpec.configure do |config|
  config.before do
    Qu.backend = mock('a backend')
  end
end