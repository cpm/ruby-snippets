# frozen_string_literal: true

# Abstract controller that implements basic CRUD operations.
# Some actions have callbacks that can be overridden in subclasses.
# If you don't like the default implementation for any action, you can override there as well.
module DefaultJsonApiCreateAction
  extend ActiveSupport::Concern

  def create
    create_security_check!

    record = initialized_create_object
    record.assign_attributes(create_params)
    record.save!

    render fast_json: fjs(records: record), status: :created

    return record
  end

  # raise an exception if the person isn't permitted to create a record
  # will fallback to create_or_update_security_check!
  def create_security_check!
    create_or_update_security_check!
  end

  # raise an exception if the person isn't permitted to create a record.
  # default implementation is noop
  def create_or_update_security_check!
  end

  # an initialized object with default attributes set
  # by default, tries `security_scope` (from Index) to get default params
  def initialized_create_object
    security_scope.new
  end

  # returns a Hash-like structure of fields which should be set on new record
  # will use `create_or_update_record_params` if this isn't implemented
  def create_params
    create_or_update_params
  end

  # returns a Hash-like structure of fields which should be set on record
  # usually the results of `deserialize_params(only: [..])`
  # defaults to no changes.
  # def create_or_update_params
  #  {}
  # end
end
