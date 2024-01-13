# frozen_string_literal: true

# This module adds formatted attributes methods we can use in serializers
# It also allows for type annotation that can be used to generate a JSON-Schema/OpenAPI structure
#
# Examples:
# string_attributes :name, :title
# date_attributes :start_at, :end_at
module AttributesFormattable
  extend ActiveSupport::Concern

  # To create a format, add it here:
  FORMATS = {
    string: -> (value) { value.to_s },
    array: -> (value) { value.to_a },
    date: -> (value) { value&.strftime('%Y-%m-%d') },
    date_time: -> (value) { value&.to_datetime&.rfc3339 },
    boolean: -> (value) { !!value },
    integer: -> (value) { value.to_i },
    rswag: -> (value) { value },
    hash: -> (value) { value.to_h },
    double: ->(value) { value.to_f }
  }.with_indifferent_access.freeze

  RSWAG_DEFAULTS = {
    string: { type: "string" },
    array: { type: "array" },
    date: { type: "string", format: "date" },
    date_time: { type: "string", format: "date-time" },
    boolean: { type: "boolean" },
    integer: { type: "integer" },
    hash: { type: "hash" },
    double: { type: "number", format: "double" },
  }

  # autogenerate all methods in FORMATS
  included do
    FORMATS.keys.each do |format|
      singleton_class.define_method("#{format}_attributes") do |*attrs, &block|
        _attributes(format, *attrs, &block)
      end

      singleton_class.alias_method "#{format}_attribute", "#{format}_attributes"
    end
  end

  module ClassMethods
    def rswag_definition
      RswagSchema::Definition.new(record_type.to_s, @rswag_attributes || {})
    end

    protected
      def _attributes(format, *keys, &block)
        # allow last argument to be an options hash
        (attributes, options) = keys.last.kind_of?(Hash) ?
          [keys[0..-2], keys.last] :
          [keys, {}]

        attributes.each do |attribute|
          @rswag_attributes ||= {}
          @rswag_attributes[attribute] = format_to_rswag(format, options)

          attribute(attribute) do |record, params|
            value = _find_value(record, attribute, params, block)
            FORMATS[format].call(value) unless value.nil? && options[:nullable] == true
          end
        end
      end

      def format_to_rswag(format, options = {})
        default_options = RSWAG_DEFAULTS[format.to_sym] || {}

        # if specified as a symbol, turn it into a type hash
        default_options = { type: default_options } if default_options.kind_of?(String)

        options.with_defaults(default_options)
      end

      def _find_value(record, attribute, params, proc)
        return record.send(attribute) if proc.nil?

        _call_proc_with_params(proc, record, params)
      end

      def _call_proc_with_params(proc, record, params)
        # procs created form symbols (:foo.to_proc or method(&:foo))
        # behave in a special way with extra arguments
        if proc.parameters == [[:rest]]
          proc.call(record)
        else
          proc.call(record, params)
        end
      end
  end
end
