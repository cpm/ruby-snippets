# frozen_string_literal: true

module CursorPagination
  class IdCursorSort < CursorSort
    def initialize(table_name:)
      super(field: "id", table_name: table_name)
    end
  end
end
