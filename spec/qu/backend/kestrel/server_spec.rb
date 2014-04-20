require 'spec_helper'
require 'qu/backend/kestrel/server'

describe Qu::Backend::Kestrel::Server do
  if Qu::Specs.perform?(described_class, :kestrel)
    let(:connection) { Qu::Backend::Kestrel::Connection.new }

    before(:each) { connection.flush('default') }

    describe "#stats" do
      it "returns hash" do
        stats = subject.stats
        stats.should be_instance_of(Hash)
        stats["time"].should be_instance_of(Fixnum)
        stats["cmd_get"].should be_instance_of(Fixnum)
        stats["queue_creates"].should be_instance_of(Fixnum)
        stats["version"].should be_instance_of(String)
        stats["reserved_memory_ratio"].should be_instance_of(Float)
      end
    end

    describe "#queue_size" do
      it "returns size" do
        connection.put('default', [""])
        connection.put('default', [""])
        subject.queue_size('default').should be(2)
      end

      it "returns 0 for down server" do
        server = described_class.new(memcache_port: 9999)
        server.queue_size('default').should be(0)
      end
    end
  end
end
