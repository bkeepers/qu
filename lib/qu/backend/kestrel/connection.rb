require_relative "2.4.1/kestrel"
require "thrift_client"
require "qu/backend/kestrel/server"

module Qu
  module Backend
    class Kestrel < Base
      class Connection
        # Private: The underlying thrift client.
        attr_reader :thrift

        # Public: Connects to a kestrel cluster
        #
        # servers: array of Qu::Backend::Kestrel::Server instances
        # options: additional Hash of options to pass to `ThriftClient`
        def initialize(servers = nil, options = {})
          @servers = servers || [Server.new]

          # If there is only one server in the list, the reconnect after timeout
          # logic will not work correctly because ThriftClient has no server to
          # fall back on.
          @servers *= 2 if @servers.length == 1

          connect_timeout = 2
          options = {
            retries: 5,
            server_max_requests: 1000,
            connect_timeout: connect_timeout,
            timeout: connect_timeout * @servers.length,
          }.merge(options)
          thrift_servers = @servers.map { |server|
            "#{server.host}:#{server.thrift_port}"
          }

          @thrift = ThriftClient.new(Thrift::Client, thrift_servers, options)
        end

        # Public: Gets items from a queue.
        #
        # options: Hash options:
        #          max_items: the maximum number of items ot fetch
        #          timeout: timeout to wait for items (0 for nonblocking)
        #          abort_timeout: if zero, items are considered confirmed, if
        #                         greater than zero, items must be confirmed
        #                         before abort_timeout milliseconds have ellapsed
        #                         or the items will be re-enqueued
        #
        # Returns zero items if no items could be fetched within the time.
        # Otherwise returns up to `max_items` or 1 by default.
        def get(queue_name, options = {})
          max_items     = options.fetch(:max_items, 1)
          timeout       = options.fetch(:timeout, 0)
          abort_timeout = options.fetch(:abort_timeout, 0)

          @thrift.get(queue_name, max_items, timeout, abort_timeout)
        end

        def put(queue_name, items)
          expiration_msec = 0
          @thrift.put(queue_name, items, expiration_msec)
        end

        def confirm(items)
          ids = items.map { |item| item.id }
          @thrift.confirm(queue_name, ids)
        end

        def abort(queue_name, items)
          ids = items.map { |item| item.id }
          @thrift.abort(queue_name, ids)
        end

        def flush(queue_name)
          @thrift.flush_queue(queue_name)
        end

        def size(queue_name)
          @servers.uniq.inject(0) do |sum, server|
            sum += server.queue_size(queue_name)
          end
        end

        def status
          Thrift::Status::VALUE_MAP[@thrift.current_status]
        end

        def connect
          @thrift.connect!
        end

        def disconnect
          @thrift.disconnect!
        end
      end
    end
  end
end
