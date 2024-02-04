# frozen_string_literal: true

# Abstract controller that implements basic CRUD operations.
# Some actions have callbacks that can be overridden in subclasses.
# If you don't like the default implementation for any action, you can override there as well.
module DefaultJsonApiDestroyAction
  extend ActiveSupport::Concern

  def destroy
    destroy_security_check!

    record = security_scope.find(params[:id])
    destroy_record!(record)

    head :no_content

    return record
  end

  # raise an exception if the person isn't permitted to destroy a record
  def destroy_security_check!
    create_or_update_security_check!
  end

  def create_or_update_security_check!; end

  # destroy the record. by default this is record.destroy, but sometimes
  # we might want to soft-delete instead
  def destroy_record!(record)
    record.destroy!
  end
end
