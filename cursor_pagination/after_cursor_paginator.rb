# frozen_string_literal: true

class CursorPagination::AfterCursorPaginator
  def initialize(scope:, sort: nil, cursor: nil)
    @scope = scope
    @sorts = [
      sort, CursorPagination::IdCursorSort.new(table_name: scope.all.model.table_name)
    ].compact
    @cursor = cursor
  end

  def all
    sort!
    filter!
  end

  private
    def filter!
      return @scope if @cursor.blank?

      serialized_field_cursors = CSV.parse_line(@cursor)
      return @scope unless serialized_field_cursors.size == @sorts.size

      sql_vars = {}
      @sorts.each.with_index do |sort, idx|
        sql_vars[sort.placeholder_name.to_sym] = sort.deserialize_cursor_to_value_proc.call(
          serialized_field_cursors[idx]
        )
      end

      sql = _comparison_sql

      # if there are aggregate functions, we need it in a HAVING
      if @sorts.map(&:field).any? { |field| field =~ /[(]/ }
        @scope = @scope.having(sql, sql_vars).group(:id)
      else
        @scope = @scope.where(sql, sql_vars)
      end
    end

    def _comparison_sql
      if @sorts.size == 2
        <<~SQL.gsub("\n", " ")
          (#{@sorts[0].to_comparison_sql}) OR
          (#{@sorts[0].to_equal_sql} AND #{@sorts[1].to_comparison_sql})
        SQL
      else
        @sorts[0].to_comparison_sql
      end
    end

    def sort!
      @scope = @scope.order(@sorts.map(&:to_sort_sql))
    end
end
