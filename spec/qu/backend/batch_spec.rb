require 'spec_helper'
require 'qu/backend/batch'
require 'qu-sqs'

Qu::Specs.setup_fake_sqs

describe Qu::Backend::Batch do

  if Qu::Specs.perform?(described_class, :sqs)
    before do
      Qu::Specs.reset_service(:sqs)
    end

    subject do
      described_class.wrap(Qu::Backend::SQS.new)
    end

    it_should_behave_like 'a backend interface'

    context 'pop-ing items in batches' do

      before do
        Qu.backend = subject
      end

      it 'should correctly pop all items in a single payload' do
        10.times do |n|
          SimpleNumericJob.create(n)
        end

        expect(subject.size).to eq(10)

        result = subject.pop

        expect(result.klass).to eq(SimpleNumericJob)
        expect(result.args.sort).to eq((0..9).to_a)
        expect(subject.size).to eq(0)
      end

      it 'should correctly separate items by type' do
        (1..5).each do |n|
          SimpleNumericJob.create(n)
        end

        (6..10).each do |n|
          OtherNumericJob.create(n)
        end

        expectations = {
          SimpleNumericJob => (1..5).to_a,
          OtherNumericJob => (6..10).to_a
        }

        result = subject.pop

        expect(expectations).to include(result.klass)
        expect(result.payloads.size).to eq(5)
        expect(result.args.sort).to eq( expectations[result.klass] )
        expect(subject.size).to eq(5)

        other_result = subject.pop

        expect(expectations).to include(other_result.klass)
        expect(other_result.payloads.size).to eq(5)
        expect(other_result.args.sort).to eq( expectations[other_result.klass] )
        expect(subject.size).to eq(0)

      end

    end

  end

end