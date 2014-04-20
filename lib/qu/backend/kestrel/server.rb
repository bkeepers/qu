require "socket"

module Qu
  module Backend
    class Kestrel < Base
      class Server
        ValidTypes = [:thrift, :memcache, "thrift", "memcache"]

        attr_reader :host, :thrift_port, :memcache_port

        def initialize(options = {})
          @host = options.fetch(:host, "127.0.0.1")
          @thrift_port = options.fetch(:thrift_port, 2229)
          @memcache_port = options.fetch(:memcache_port, 22134)
        end

        # TODO: add timeout for socket operations
        def stats
          socket = TCPSocket.new(host, memcache_port)
          socket.puts "STATS"

          stats = {}
          while line = socket.readline
            if line =~ /^STAT (\w+) (\S+)/
              stat_name, stat_value = $1, deserialize_stat_value($2)
              stats[stat_name] = stat_value
            elsif line =~ /^END/
              socket.close
              break
            else
              puts "unmatched line: #{line}"
            end
          end

          stats
        ensure
          socket.close if socket && !socket.closed?
        end

        def queue_size(queue_name)
          begin
            stats.fetch("queue_#{queue_name}_items", 0)
          rescue => exception
            0
          end
        end

        private

        def deserialize_stat_value(value)
          case value
          when /^\d+\.\d+$/
              value.to_f
          when /^\d+$/
              value.to_i
          else
            value
          end
        end
      end
    end
  end
end
