# frozen_string_literal: true

# Abstract controller that implements basic CRUD operations.
# Some actions have callbacks that can be overridden in subclasses.
# If you don't like the default implementation for any action, you can override there as well.
module DefaultJsonApiIndexAction
  extend ActiveSupport::Concern

  class_methods do
    def security_scope(&block)
      define_method(:security_scope) do
        self.instance_eval(&block)
      end
    end
  end

  def index
    filtered_scope = index_filters(security_scope)
    (final_scope, meta) = after_cursor_paginate(
      scope: filtered_scope,
      sort: index_active_sorter
    )

    render fast_json: fjs(records: final_scope, meta: meta)
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
  # out: scope with params[:filter] conditions added on
  # defaults to implement id. override to add additional filters
  def index_filters(scope)
    scope = apply_simple_filters(scope, :id)

    with_filter(:updated_after).each do |value|
      scope = scope.where("#{scope.table_name}.updated_at > ?", Time.at(value.to_i))
    end

    scope
  end

  def index_valid_sorters
    {
      created_at: CursorPagination::DateCursorSort.new(field: :created_at),
      updated_at: CursorPagination::DateCursorSort.new(field: :updated_at)
    }.with_indifferent_access
  end

  def index_active_sorter
    return if params[:sort].blank?

    index_valid_sorters[params[:sort]]
  end
end
