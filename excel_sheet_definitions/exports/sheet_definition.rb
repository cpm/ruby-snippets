# frozen_string_literal: true

# TODO: this might move to /app/models? or /lib?
class Exports::SheetDefinition

  attr_accessor :headers

  def initialize
    @name = "Untitled"
    @headers = []
  end

  def header_names
    @headers.map(&:name)
  end

  # if we use `worksheet_name=`, the DSL will need self.worksheet_name to use
  # this method instead of creating a local variable.
  # instead, let's make an optional argument to set and always returns
  def worksheet_name(name = nil)
    @worksheet_name = name if name

    @worksheet_name
  end

  # display header, optional type for excel, and the block to turn the record
  # into the value for the row
  def header(name, type = nil, &block)
    @headers << Header.new(name, type: type, &block)
  end

  # macro to merge two definitions together.
  # headers from `instance` are added in order when called
  def include_headers(instance)
    instance.headers.each do |current_header|
      header current_header.name, current_header.type, &(current_header.block)
    end
  end

  # evaluate how the records will show up
  def record_values(records)
    records.map do |record|
      @headers.map do |header|
        header.to_value(record)
      end
    end
  end

  # add the a worksheet to the package with headers and records indicated
  def add_worksheet!(package:, records:)
    package.workbook.add_worksheet(name: @worksheet_name) do |sheet|
      # add headers
      sheet.add_row(@headers.map(&:name))

      types = @headers.map(&:type)

      self.record_values(records).each do |row|
        sheet.add_row(row, types: types)
      end
    end
  end

  class << self
    # make a DSL so we can do:
    #
    # SheetDefinition.configure do
    #   worksheet_name "Sheet Name"
    #
    #   row "First Name" do |record|
    #     record.some_association.first_name.upcase
    #   end
    # end.add_worksheet!(workbook: wb, records: scope)

    def configure(&block)
      self.new.tap do |instance|
        instance.instance_eval(&block)
      end
    end
  end

  class Header
    def initialize(name, type: nil, &block)
      @name = name
      @type = type
      @block = block
    end

    attr_reader :name, :type, :block

    def to_value(record)
      @block.call(record) rescue ""
    end
  end
end
