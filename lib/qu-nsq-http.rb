require 'qu'
require 'qu/backend/nsq_http'

Qu.backend = Qu::Backend::NSQHTTP.new
