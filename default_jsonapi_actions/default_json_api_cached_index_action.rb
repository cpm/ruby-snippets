# frozen_string_literal: true

# Abstract controller that implements basic CRUD operations.
# Some actions have callbacks that can be overridden in subclasses.
# If you don't like the default implementation for any action, you can override there as well.
module DefaultJsonApiCachedIndexAction
  extend ActiveSupport::Concern

  def index
    pre_filtered_scope = index_pre_cache_filters(security_scope)

    json = Rails.cache.fetch(*cache_fetch_params(pre_filtered_scope)) do
      scope = index_post_cache_filters(pre_filtered_scope)

      (final_scope, meta) = after_cursor_paginate(scope: scope, sort: index_active_sorter)

      fjs(records: final_scope, meta: meta).serializable_hash.to_json
    end

    render fast_json: json
  end

  def cache_fetch_params(scope)
    ary = [ cache_key(scope) ]

    if cache_expires_in
      ary << { expires_in: cache_expires_in }
    end

    ary
  end

  def cache_key(scope)
    [params.permit!]
  end

  # specify an amount of time for the cache, something like `5.minutes`
  # default implementation returns nil, which doesn't do a cache time
  def cache_expires_in
  end

  # in: ActiveRecord scope
  # out: scope with some params[:filter] conditions applied
  # this happens before the cache block so you can use `scope` as a cache key with fewer records
  # defaults to filtering `id` and `updated_after`
  def index_pre_cache_filters(scope)
    scope = apply_simple_filters(scope, :id)

    with_filter(:updated_after).each do |value|
      scope = scope.where("#{scope.table_name}.updated_at > ?", Time.at(value.to_i))
    end

    scope
  end

  # returns ActiveRecord scope, doing any security checks for current_admin_user if needed.
  # used by all actions.
  #
  # NOTE: All Default* modules will implement this by raising, so implement your
  #       `security_scope` method after any includes
  # def security_scope
  #  raise NotImplementedError
  # end

  # in: ActiveRecord scope
  # out: scope with some params[:filter] conditions applied
  # this happens in the cache block so if applying some filters are expensive because you need
  # to load records into memory to add there `where` conditions, you can cache that piece.
  # default implmentation doesn't add any filters
  def index_post_cache_filters(scope)
    scope
  end

  def index_valid_sorters
    {
      created_at: CursorPagination::DateCursorSort.new(field: :created_at),
      updated_at: CursorPagination::DateCursorSort.new(field: :updated_at)
    }.with_indifferent_access
  end

  def index_default_sorter
    nil
  end

  def index_active_sorter
    return index_default_sorter if params[:sort].blank?

    index_valid_sorters[params[:sort]]
  end
end
