# frozen_string_literal: true

require 'rails_helper'

describe AttributesFormattable, type: :model do

  let(:record) do
    OpenStruct.new(
      id: "IDENTIFIER",
      string_test: 1.5,
      array_test: { a: :b },
      date_test: DateTime.new(2020, 1, 2, 3, 4, 5),
      date_time_test: DateTime.new(2020, 1, 2, 3, 4, 5),
      boolean_test: "hello",
      integer_test: "12345",
      double_test: "12345.6789"
    )
  end

  let(:serializer_klass) do
    Class.new do
      # creating real classes in tests is bad in rspec because it pollutes the global namespace so
      # different tests can clobber each other. however, anonymous classes don't have a name.
      #
      # FastJsonapi will fail without a name, so create a class method.
      # Using `define_singleton` instead of `def self.method` because we're in a closure so `self`
      # is the `let` block's `self`
      define_singleton_method(:name) { "TestSerializer" }

      include JSONAPI::Serializer
      include AttributesFormattable

      string_attributes :string_test
      array_attributes :array_test
      date_attributes :date_test
      date_time_attributes :date_time_test
      double_attributes :double_test

      string_attributes :string_block_test do |record|
        record.string_test + 1
      end

      boolean_attributes :boolean_test

      date_attributes(:date_option_test, nullable: true) do |record|
        record.date_test
      end

      integer_attributes :integer_test
    end
  end

  context "#*_attribute" do
    context ".rswag_definition" do
      subject(:actual_rswag) { serializer_klass.rswag_definition }

      let(:expected_rswag) do
        RswagSchema::Definition.new "test",
          string_test: "string",
          array_test: "array",
          date_test: { type: "string", format: "date" },
          date_time_test: { type: "string", format: "date-time" },
          double_test: { type: "number", format: "double" },
          string_block_test: "string",
          boolean_test: { type: "boolean" },
          date_option_test: { type: "string", format: "date", nullable: true },
          integer_test: { type: "integer" }
      end

      it "has an expected #as_single representation" do
        expect(actual_rswag.as_single).to match(expected_rswag.as_single)
      end
    end

    context "#serialized_json" do
      subject(:json) { serializer_instance.serializable_hash.to_json }
      let(:serializer_instance) { serializer_klass.new(record) }

      it "transforms json to the appropriate type" do
        expect(json).to be_json_sym(
          data: {
            attributes: {
              array_test: [%w[a b]],
              date_test: "2020-01-02",
              date_time_test: "2020-01-02T03:04:05+00:00",
              string_test: "1.5",
              string_block_test: "2.5",
              date_option_test: "2020-01-02",
              boolean_test: true,
              integer_test: 12345,
              double_test: 12345.6789,
            },
            id: "IDENTIFIER",
            type: "test"
          }
        )
      end

      context 'with nil values' do
        let(:record) do
          OpenStruct.new(
            id: 'IDENTIFIER',
            string_test: nil,
            array_test: nil,
            date_test: nil,
            date_time_test: nil,
            boolean_test: nil,
            integer_test: nil,
            double_test: nil
          )
        end

        let(:serializer_klass) do
          Class.new do
            define_singleton_method(:name) { 'TestSerializer' }

            include JSONAPI::Serializer
            include AttributesFormattable

            string_attributes :string_test
            array_attributes :array_test
            date_attributes :date_test
            date_time_attributes :date_time_test
            double_attributes :double_test
            boolean_attributes :boolean_test
            integer_attributes :integer_test
          end
        end

        it 'transforms json to the appropriate type' do
          expect(json).to be_json_sym(
            data: {
              attributes: {
                array_test: [],
                date_test: nil,
                date_time_test: nil,
                string_test: '',
                boolean_test: false,
                integer_test: 0,
                double_test: 0.0,
              },
              id: 'IDENTIFIER',
              type: 'test'
            }
          )
        end

        context 'with nullable option' do
          let(:serializer_klass) do
            Class.new do
              define_singleton_method(:name) { 'TestSerializer' }

              include JSONAPI::Serializer
              include AttributesFormattable

              string_attributes :string_test, nullable: true
              array_attributes :array_test, nullable: true
              date_attributes :date_test, nullable: true
              date_time_attributes :date_time_test, nullable: true
              double_attributes :double_test, nullable: true
              boolean_attributes :boolean_test, nullable: true
              integer_attributes :integer_test, nullable: true
            end
          end

          it 'transforms json to the appropriate type' do
            expect(json).to be_json_sym(
              data: {
                attributes: {
                  array_test: nil,
                  date_test: nil,
                  date_time_test: nil,
                  string_test: nil,
                  boolean_test: nil,
                  integer_test: nil,
                  double_test: nil,
                },
                id: 'IDENTIFIER',
                type: 'test'
              }
            )
          end
        end
      end
    end
  end
end
