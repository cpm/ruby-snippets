# frozen_string_literal: true

RSpec.shared_examples "rswag:index:no filters" do
  context "no filters" do
    let(:expected_results) { records }

    run_test! do
      expect(response.body).to eq expected_serializer.serializable_hash.to_json
    end
  end
end

RSpec.shared_examples "rswag:index:filter[id]" do
  context "filter[id]" do
    let("filter[id]") { records.first.id }
    let(:expected_results) { [records.first] }

    run_test! do
      expect(response.body).to eq expected_serializer.serializable_hash.to_json
    end
  end
end

RSpec.shared_examples "filter[updated_after]" do
  context "filter[updated_after]" do
    before { records.last.update(updated_at: 1.year.from_now) }
    let("filter[updated_after]") { 6.months.from_now.to_i }
    let(:expected_results) { [records.last] }

    run_test! do
      expect(response.body).to eq expected_serializer.serializable_hash.to_json
    end
  end
end
