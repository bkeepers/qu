require 'securerandom'
require 'active_support/notifications'
require 'qu/instrumentation/statsd_subscriber'

ActiveSupport::Notifications.subscribe /\.#{Qu::InstrumentationNamespace}$/,
  Qu::Instrumentation::StatsdSubscriber
