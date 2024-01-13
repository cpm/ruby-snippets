# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RswagSchema::Definition, type: :model do
  subject(:definition) do
    described_class.new "model",
      simple: :attribute,
      complex: { type: :attribute, extra: :value }
  end

  let(:single_output_with_id) do
    {
      properties: {
        attributes: {
          type: :object,
          properties: {
            complex: { extra: :value, type: :attribute },
            simple: { type: :attribute },
          },
          required: contain_exactly(*%w[complex simple])
        },
        type: { type: :string, enum: ["model"] },
        id: { type: :string }
      },
      required: contain_exactly(*%w[id type attributes]),
      type: :object,
    }
  end

  let(:single_output_without_id) do
    {
      properties: {
        attributes: {
          type: :object,
          properties: {
            complex: { extra: :value, type: :attribute },
            simple: { type: :attribute },
          },
          required: contain_exactly(*%w[complex simple])
        },
        type: { type: :string, enum: ["model"] },
      },
      required: contain_exactly(*%w[type attributes]),
      type: :object,
    }
  end

  describe "#as_single" do
    subject { definition.as_single }

    let(:expected_output) do
      {
        type: :object,
        properties: {
          data: single_output_with_id
        }, required: %w[data]
      }
    end

    it { is_expected.to match(expected_output) }
  end

  describe '#as_create_payload' do
    subject { definition.as_create_payload }

    let(:expected_output) do
      {
        type: :object,
        properties: {
          data: single_output_without_id
        }, required: %w[data]
      }
    end

    it { is_expected.to match(expected_output) }

  end

  describe "#as_array" do
    subject { definition.as_array }

    let(:expected_output) do
      {
        type: :object,
        properties: {
          data: {
            type: :array,
            items: single_output_with_id
          }
        }, required: %w[data]
      }
    end

    it { is_expected.to match expected_output }
  end

  describe "#as_paginated_array" do
    subject { definition.as_paginated_array }

    let(:expected_output) do
      {
        type: :object,
        properties: {
          data: {
            type: :array,
            items: single_output_with_id
          },
          meta: {
            type: :object,
            properties: {
              page: {
                type: :object,
                properties: {
                  after: { type: :string }
                }
              },
              count: { type: :integer, nullable: true }
            },
            required: %w[page]
          }
        }, required: %w[data meta]
      }
    end

    it { is_expected.to match expected_output }
  end

  describe "#as_counters" do
    subject { definition.as_counters }

    let(:expected_output) do
      {
        type: :object,
        required: %w[data],
        properties: {
          data: {
            type: :array,
            items: {
              type: :object,
              required: %w[id type attributes],
              properties: {
                id: { type: :string },
                type: { type: :string, enum: ['model'] },
                attributes: {
                  type: :object,
                  required: %w[count],
                  properties: {
                    count: { type: :integer }
                  }
                }
              }
            }
          }
        }
      }
    end

    it { is_expected.to match expected_output }
  end
end
