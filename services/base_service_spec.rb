# frozen_string_literal: true

require 'rails_helper'

module BaseServiceTests
  class TestReturn
    include BaseService

    def _call!; ["test passed"]; end
  end

  class TestRaises
    include BaseService

    def _call!; raise "massive failure"; end
  end
end

RSpec.describe BaseService, type: :model do
  context "when no args are given" do
    subject(:perform_request) do
      trial_class.call
    end

    context "when TestReturn" do
      let(:trial_class) { BaseServiceTests::TestReturn }

      it { is_expected.to be_success }
      it "returns ['test passed']" do
        expect(subject.results).to eq ["test passed"]
      end
    end

    context "when TestRaises" do
      let(:trial_class) { BaseServiceTests::TestRaises }

      it { is_expected.not_to be_success }
      it "has an error message" do
        expect(subject.errors).to include("massive failure")
      end
    end
  end
end
