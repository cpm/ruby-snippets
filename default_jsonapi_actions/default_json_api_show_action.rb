# frozen_string_literal: true

# Abstract controller that implements basic CRUD operations.
# Some actions have callbacks that can be overridden in subclasses.
# If you don't like the default implementation for any action, you can override there as well.
module DefaultJsonApiShowAction
  extend ActiveSupport::Concern

  def show
    show_security_check!

    record = security_scope.find(params[:id])
    render fast_json: fjs(records: record)
  end

  # raise an exception if the person isn't permitted to request the
  def show_security_check!
  end
end
