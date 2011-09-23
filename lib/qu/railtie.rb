require 'qu'

module Qu
  class Railtie < Rails::Railtie
    rake_tasks do
      load "qu/tasks.rb"
    end
  end
end
