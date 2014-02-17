require 'spec_helper'
require 'qu/util/thread_safe_hash'

describe Qu::Util::ThreadSafeHash do
  it 'should wrap a hash and dup it' do
    options = {options: 'some options'}
    hash = Qu::Util::ThreadSafeHash.new(options)
    options[:other] = 'some-value'
    expect(hash[:other]).to be_nil
  end

  it 'should delete by key' do
    hash = Qu::Util::ThreadSafeHash.new(options: 'some options')
    hash.delete(:options)
    expect(hash[:options]).to be_nil
  end

  it 'should a copy of the values' do
    hash = Qu::Util::ThreadSafeHash.new(options: 'some options', some: 'value')
    values = hash.values
    hash.delete(:options)
    expect(values).to eq(['some options', 'value'])
  end

  it 'should have a size' do
    hash = Qu::Util::ThreadSafeHash.new(options: 'some options', some: 'value')
    expect(hash.size).to eq(2)
  end

  it 'should be navigable' do
    hash = Qu::Util::ThreadSafeHash.new(options: 'some options', some: 'value')
    pairs = []
    hash.each do |key,value|
      pairs << [key,value]
    end

    expect(pairs).to eq([[:options, 'some options'], [:some, 'value']])
  end
end
