# frozen_string_literal: true

module CursorPagination
  # field => SQL for the SQL expression that we can compare (<=>). usually column name is fine.
  # direction => asc/desc. default asc
  # serialize_record_to_cursor_proc => turn a record into a cursor representing `field`
  # deserialize_cursor_to_value_proc => takes cursor for this sort and deserializes into a value
  #                                     that can be used as a where matching `field`
  class CursorSort
    attr_reader :field, :direction, :table_name
    attr_reader :serialize_record_to_cursor_proc, :deserialize_cursor_to_value_proc

    def initialize(field:, direction: "ASC", table_name: nil,
      serialize_record_to_cursor_proc: nil,
      deserialize_cursor_to_value_proc: nil
    )

      @field = field.to_s
      @direction = direction.to_s.upcase
      @table_name = table_name.to_s

      @serialize_record_to_cursor_proc = serialize_record_to_cursor_proc || Proc.new do |record|
        record.read_attribute(field)
      end

      @deserialize_cursor_to_value_proc = deserialize_cursor_to_value_proc || Proc.new do |value|
        value
      end

      raise ArgumentError, "Bad direction" unless %w[ASC DESC].include?(@direction)
    end

    def qualified_field
      if table_name.present?
        "`#{table_name}`.`#{field}`"
      else
        field
      end
    end

    def placeholder_name
      field.to_s.downcase.gsub(/[^a-z]/, "_")
    end

    # TODO: param here to specify diff behavior for before/after cursor
    def to_comparison_sql
      dir = direction.to_s
      if dir == "ASC"
        Arel.sql("#{qualified_field} > :#{placeholder_name}")
      elsif dir == "DESC"
        Arel.sql("#{qualified_field} < :#{placeholder_name}")
      else
        raise "impossible"
      end
    end

    def to_equal_sql
      Arel.sql("#{qualified_field} = :#{placeholder_name}")
    end

    def to_sort_sql
      if direction == "ASC"
        Arel.sql("#{qualified_field}")
      else
        Arel.sql("#{qualified_field} #{direction}")
      end
    end
  end
end
