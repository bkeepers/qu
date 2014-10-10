require 'net/http'
require 'securerandom'

module Qu
  module Backend
    class NSQHTTP < Base
      attr_writer :channel_name

      class NSQError < StandardError
      end

      def push(payload)
        payload.id = SecureRandom.uuid
        response = connection.post("/pub?topic=#{payload.queue}", dump(payload.attributes_for_push))
        raise NSQError, "Push to NSQ unsuccessful: #{response.inspect}" unless response.code =~ /^2/
        payload
      end

      # See http://dev.bitly.com/nsq.html#v3_nsq_stats
      def size(queue_name = 'default')
        size = 0
        response = connection.get("/stats?format=json")
        stats = Qu.load_json(response.body)['data']
        if topic = stats['topics'].detect { |topic| topic['topic_name'] == queue_name }
          if channel = topic['channels'].detect { |channel| channel['channel_name'] == channel_name }
            size = channel['depth'] + channel['deferred_count']
          end
        end
        size
      end

      def clear(queue_name = 'default')
        response = connection.post("/channel/empty?topic=#{queue_name}&channel=#{channel_name}", "")
        response.body
      end

      def channel_name
        @channel_name ||= 'qu'
      end

      def connection
        @connection ||= Net::HTTP.new('127.0.0.1', '4151')
      end
    end
  end
end
