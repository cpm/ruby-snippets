# frozen_string_literal: true

module FilterProcessable
  extend ActiveSupport::Concern

  protected

    def with_filter_processor
      @_with_filter_processor ||= WithFilterProcessor.new(filters)
    end

    def with_filter(*filter_names, delimiter: ",", &block)
      with_filter_processor.process(*filter_names, delimiter: delimiter, &block)
    end

    def filter_params
      with_filter_processor.filters || {}
    end

    def no_filters?
      with_filter_processor.no_filters?
    end

    def apply_simple_filters(scope, *filters)
      filters.each do |column|
        with_filter(column) do |values|
          scope = scope.where(column => values)
        end
      end

      return scope
    end
end
