# frozen_string_literal: true

class ActiveModelSerializer < ActiveModel::Serializer
  include AttributesFormattable

  # This method lets ActiveModel::Serializer know what serializer should be used
  # to serialize relations if no one is specified by the relation option like that:
  #
  # belongs_to :admin_user, serializer: Api::V1::AdminUserSerializer
  def self.serializer_for(model, options)
    super
  end

  protected

    def _find_value(record, attribute, params, proc)
      return record.object.send(attribute) if proc.nil?

      _call_proc_with_params(proc, record.object, params)
    end
end