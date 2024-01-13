# frozen_string_literal: true

module RswagSchema
  class Definition
    attr_accessor :name, :input_attributes

    def initialize(name, attributes = {})
      self.name = name
      self.input_attributes = attributes
    end

    def as_array
      rswag_object(
        data: { type: :array, items: model_with_id }
      )
    end

    def as_single
      rswag_object(data: model_with_id)
    end

    def as_create_payload(only: [], exclude: [])
      rswag_object(data: model_without_id(only: only, exclude: exclude))
    end

    def as_paginated_array
      rswag_object(
        data: { type: :array, items: model_with_id },
        meta: rswag_object(
          page: rswag_object(after: { type: :string, optional: true }),
          count: { type: :integer, optional: true, nullable: true }
        )
      )
    end

    def as_counters
      rswag_object(
        data: {
          type: :array,
          items: rswag_object(
            id: { type: :string },
            type: { type: :string, enum: [name] },
            attributes: rswag_object(
              count: { type: :integer }
            )
          )
        }
      )
    end

    private
      def rswag_object(attributes = {})
        # assume everything is required unless flagged explicitly in a complex value
        optional_attributes = []

        attribute_properties = attributes.each_with_object({}) do |(key, value), memo|
          memo[key] = if value.kind_of?(Hash)
            optional_attributes << key.to_s if value[:optional]
            value.except(:optional)
          else
            { type: value }
          end
        end

        {
          type: :object,
          properties: attribute_properties,
        }.tap do |hsh|
          # we assume everything is required unless one of the attributes is:
          # { attr: { optional: true }}
          required_attributes = attribute_properties.keys.map(&:to_s) - optional_attributes

          # we cannot have a required key if it's empty
          hsh[:required] = required_attributes if required_attributes.any?
        end
      end

      def model_without_id(only: [], exclude: [])
        attrs = input_attributes

        attrs = attrs.slice(only) if only.present?
        attrs = attrs.reject { |key, value| exclude.include?(key) }

        rswag_object(
          type: { type: :string, enum: [name] },
          attributes: rswag_object(attrs)
        )
      end

      def model_with_id
        rswag_object(
          id: { type: :string },
          type: { type: :string, enum: [name] },
          attributes: rswag_object(input_attributes)
        )
      end
  end
end
