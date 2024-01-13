# frozen_string_literal: true

# Suppose you want to implement:
# with_filter(:foo, :bar).each do |foo, bar|
#   some block
# end
#
# with the assumption you have `params[:filter] = { foo: "a,b", bar: "c,d" }`
# 
# This will DRY up creating a with_filter that will return `some block` twice
# with the following params:
#  1. foo="a", bar="c"
#  2. foo="b", bar="d"

class WithFilterProcessor
  attr_accessor :filters

  def initialize(filters)
    @filters = filters
  end

  def no_filters?
    return true if filters.blank?
    return true if [Hash, ActionController::Parameters].none? { |klass|
      filters.is_a?(klass)
    }

    return
  end

  def process(*filter_names, skip_unpaired: false, delimiter: ",", &block)
    return [] if no_filters?

    param_values = {}
    filter_names.each do |filter_name|
      param_values[filter_name] = (filters[filter_name] || "").split(delimiter)
    end

    param_sizes = param_values.values.map(&:size)

    results = begin
      # we only want a one dimensional array for single filters
      if filter_names.size == 1
        param_values.values.first
      else
        # take advantage of how indexing an undefined index is nil, not an error
        limit = skip_unpaired ? param_sizes.min : param_sizes.max
        limit.times.map do |idx|
          filter_names.map do |name|
            param_values[name][idx]
          end
        end
      end
    end

    # result.blank? happens if multiple filters, one not present in params, and skip_unpaired
    if block && results.present?
      block.call(results)
    else
      results.to_enum
    end
  end
end
