# frozen_string_literal: true

module Filterable
  extend ActiveSupport::Concern

  protected

    def filter_params
      @filter_params ||= params[:filter] || {}
    end

    # give a list of filter names and return an array of values grouped positionally.
    # example:
    # => with_filter("a") when filter: { a: "1,2,3", b: "4,5" }
    # will result in: [1,2,3]
    # => with_filter("a", "b") when filter: { a: "1,2,3", b: "4,5" }
    # will result in:
    # => [[1,4], [2,5], [3,nil]]
    # if skip_unpaired is true, [3,nil] would not be in the set
    # delimiter is by default ',', but can be anything that is a legal arg for String#split
    def with_filter(*filter_names, skip_unpaired: false, delimiter: ",", &block)
      @_with_filter_processor ||= WithFilterProcessor.new(params[:filter])

      @_with_filter_processor.process(*filter_names,
        skip_unpaired: skip_unpaired,
        delimiter: delimiter,
        &block
      )
    end
end
