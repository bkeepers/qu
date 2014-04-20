require "socket"

module Qu
  module Backend
    class Kestrel < Base
      class Server
        ValidTypes = [:thrift, :memcache, "thrift", "memcache"]

        FloatValueRegex   = /^\d+\.\d+$/
        IntegerValueRegex = /^\d+$/

        StatLineRegex = /^STAT (\w+) (\S+)/
        EndLineRegex  = /^END/

        attr_reader :host, :thrift_port, :memcache_port

        def initialize(options = {})
          @host = options.fetch(:host, "127.0.0.1")
          @thrift_port = options.fetch(:thrift_port, 2229)
          @memcache_port = options.fetch(:memcache_port, 22134)
          @timeout = options.fetch(:timeout, 3)
        end

        def stats
          socket = nil
          Timeout.timeout(@timeout) {
            socket = TCPSocket.new(host, memcache_port)
            socket.puts "STATS"

            stats = {}
            while line = socket.readline
              case line
              when StatLineRegex
                stat_name, stat_value = $1, deserialize_stat_value($2)
                stats[stat_name] = stat_value
              when EndLineRegex
                socket.close
                break
              end
            end

            stats
          }
        ensure
          socket.close if socket && !socket.closed?
        end

        def queue_size(queue_name)
          stats.fetch("queue_#{queue_name}_items", 0)
        rescue => exception
          0
        end

        private

        def deserialize_stat_value(value)
          case value
          when FloatValueRegex
              value.to_f
          when IntegerValueRegex
              value.to_i
          else
            value
          end
        end
      end
    end
  end
end
