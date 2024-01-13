# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WithFilterProcessor, type: :model do
  context '#process' do
    let(:processor) { described_class.new(inputs) }
    let(:inputs) do
      { foo: "a,b", bar: "c" }
    end

    let(:collector) { [] }

    context "checking for one value" do
      context "without block" do
        subject { processor.process(:foo) }

        it { is_expected.to contain_exactly("a", "b") }
      end

      context "with block" do
        subject { processor.process(:foo) {|args| collector << args } }

        its_block { is_expected.to change { collector }.to([["a", "b"]]) }
      end
    end

    context "checking for multiple values" do
      context "without block" do
        subject { processor.process(:foo, :bar) }

        it { is_expected.to contain_exactly(["a", "c"], ["b", nil]) }
      end

      context "with block" do
        subject { processor.process(:foo, :bar) { |args| collector << args }}

        its_block do
          is_expected.to change { collector }.to([[["a", "c"], ["b", nil]]])
        end
      end
    end

    context "checking for multiple values, skipping uneven pairs" do
      context "without block" do
        subject { processor.process(:foo, :bar, skip_unpaired: true) }

        it { is_expected.to contain_exactly(["a", "c"]) }
      end

      context "with block" do
        subject do
          processor.process(:foo, :bar, skip_unpaired: true) do |args|
            collector << args
          end
        end

        its_block do
          is_expected.to change { collector }.to([[["a", "c"]]])
        end
      end
    end

    context "checking different delimiter" do
      let(:inputs) do
        { foo: "a \tb" }
      end

      context "without block" do
        subject { processor.process(:foo, delimiter: /\s+/) }

        it { is_expected.to contain_exactly("a", "b") }
      end

      context "with block" do
        subject do
          processor.process(:foo, delimiter: /\s+/) {|args| collector << args }
        end

        its_block { is_expected.to change { collector }.to([["a", "b"]]) }
      end
    end
  end
end
