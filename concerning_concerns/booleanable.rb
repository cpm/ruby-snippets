# frozen_string_literal: true

module Booleanable
  extend ActiveSupport::Concern

  protected

    def parse_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value) || false # prevents nil
    end
end
