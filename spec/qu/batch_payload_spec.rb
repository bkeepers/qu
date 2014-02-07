require 'spec_helper'
require 'qu/batch_payload'

class ExampleJob < Qu::Job

  attr_reader :numbers

  def initialize(*numbers)
    @numbers = numbers
  end

end

describe Qu::BatchPayload do

  let :payloads do
    (1..10).map do |n|
      Qu::Payload.new(:klass => "ExampleJob", :args => n)
    end
  end

  let :batch do
    Qu::BatchPayload.new(:payloads => payloads, :queue => 'default', :klass => 'ExampleJob')
  end

  it 'should set the args to the collection of args of all payloads' do
    expect(batch.args).to eq((1..10).to_a)
  end

  it 'should create the worker class with the available args' do
    expect(batch.job.numbers).to eq((1..10).to_a)
  end

end