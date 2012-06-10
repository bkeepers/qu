require "qu"

Qu.configure do |c|
  c.logger = Logger.new(STDOUT)
  c.logger.level = Logger::INFO
end

if defined?(Rails)
  if defined?(Rails::Railtie)
    require 'qu/railtie'
  else
    Qu.logger = Rails.logger
  end
end

