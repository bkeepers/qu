require 'qu'

module Qu
  class Railtie < Rails::Railtie
    rake_tasks do
      load "qu/tasks.rb"
    end

    initializer "qu.logger" do |app|
      Qu.logger = Rails.logger
    end
  end
end
