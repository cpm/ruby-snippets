# frozen_string_literal: true

require 'rails_helper'

module AtomicServiceTests
  class TestReturn
    include AtomicService

    def _call!; ["test passed"]; end
  end

  class TestRaises
    include AtomicService

    def _call!; raise "massive failure"; end
  end

  class TestTransactionSuccess
    include AtomicService

    def _call!; FactoryBot.create(:institution); end
  end

  class TestTransactionFailure
    include AtomicService

    def _call!; FactoryBot.create(:institution); raise "nope"; end
  end
end

RSpec.describe AtomicService, type: :model do
  context "when no args are given" do
    subject(:perform_request) do
      trial_class.call
    end

    context "when TestReturn" do
      let(:trial_class) { AtomicServiceTests::TestReturn }

      it { is_expected.to be_success }
      it "returns ['test passed']" do
        expect(subject.results).to eq ["test passed"]
      end
    end

    context "when TestRaises" do
      let(:trial_class) { AtomicServiceTests::TestRaises }

      it { is_expected.not_to be_success }
      it "has an error message" do
        expect(subject.errors).to include("massive failure")
      end
    end

    context "when TestTransactionSuccess" do
      let(:trial_class) { AtomicServiceTests::TestTransactionSuccess }

      it { is_expected.to be_success }
      it "makes a institution" do
        expect { subject }.to change { Institution.count }.by(1)
      end
    end

    context "when TestTransactionFailuer" do
      let(:trial_class) { AtomicServiceTests::TestTransactionFailure }

      it { is_expected.not_to be_success }
      it "institution is not creaated" do
        expect { subject }.not_to change { Institution.count }
      end
    end
  end
end
