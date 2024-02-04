# frozen_string_literal: true

module ActiveIncludable
  extend ActiveSupport::Concern

  protected

    # gives a list of include params that are allowed
    def active_includes(allow_list)
      params[:include].to_s.split(',') & allow_list
    end
end
