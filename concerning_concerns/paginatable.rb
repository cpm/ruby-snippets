# frozen_string_literal: true

module Paginatable
  extend ActiveSupport::Concern

  protected

    def page_params
      @page_params ||= params[:page] || {}
    end

    # find the smallest limit.. don't allow users to pass in
    # larger limits than the system allows
    # limits of 0 or less should be ignored
    # TODO: moved here as is. Refactor this!
    def paginate(scope, options = {})
      limit = [
        page_params[:size].to_i,
        options[:limit].to_i,
        1000
      ].reject { |limit| limit <= 0 }.min

      # first page is 1
      current_page = [page_params[:number].to_i || 1, 1].max

      total_records = scope.count
      total_pages = (total_records / limit) + 1
      scope.limit(limit)
      scope.offset((current_page - 1) * limit)

      [scope, {
        page_size: limit,
        current_page: current_page,
        total_records: total_records,
        total_pages: total_pages
      }]
    end

    # find the smallest limit.. don't allow users to pass in
    # larger limits than the system allows
    # limits of 0 or less should be ignored
    # TODO: moved here as is. Refactor this!
    def cursor_paginate(original_scope, options = {})
      limit = [
        page_params[:size].to_i,
        options[:limit].to_i,
        100
      ].reject { |limit| limit <= 0 }.min

      scope = original_scope.limit(limit)

      after = page_params[:after].to_i || 0
      scope = scope.offset(after) if after > 0

      # count can get weird when mixed with ORDER BY, so arrayify and count
      size = scope.to_a.size
      next_after = size + after

      meta = {}
      unless original_scope.offset(next_after).limit(1).empty?
        meta[:page] = { cursor: next_after }
      end

      [scope, meta]
    end
end
