# frozen_string_literal: true

module CursorPagination
  class DateCursorSort < CursorSort
    def initialize(field:, direction: "ASC", table_name: nil)
      serializer = lambda do |record|
        record.send(field).to_i || 0
      end

      deserialier = lambda do |epoc|
        Time.at(epoc.to_i)
      end

      super(
        field: field,
        table_name: table_name,
        direction: direction,
        serialize_record_to_cursor_proc: serializer,
        deserialize_cursor_to_value_proc: deserialier
      )
    end
  end
end
