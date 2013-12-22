require 'aws/dynamo_db'

module Qu
  module Backend
    class AWS
      class Dynamo
        class State
          include Enumerable

          # Private
          def self.table
            @table ||= begin
              dynamo = ::AWS::DynamoDB.new
              table = dynamo.tables[ENV.fetch("QU_DYNAMO_TABLE_NAME", "qu_gem")]
              table.load_schema
            end
          end

          # Private
          attr_reader :namespace

          # Private
          attr_reader :table

          def initialize(namespace, options = {})
            @namespace = namespace
            @table = options.fetch(:table) { self.class.table }
          end

          def each
            table.items.query(:hash_value => namespace).each { |item|
              yield({:id => item.range_value})
            }
          end

          def register(id)
            doc = {
              :namespace => namespace,
              :id => id,
              :created_at => Time.now.to_i,
            }
            options = {
              :unless_exists => [namespace,  id],
            }
            table.items.put(doc, options)
          end

          def unregister(*ids)
            ids = Array(ids).flatten
            namespaced_ids = ids.map { |id| [namespace, id] }
            table.batch_write(:delete => namespaced_ids)
          end
        end
      end
    end
  end
end
