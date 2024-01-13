# frozen_string_literal: true

# AtomicService wraps BaseService in a transaction. See BaseService for docs.
module AtomicService
  extend ActiveSupport::Concern
  include BaseService

  def call
    begin
      call!
    rescue
      OpenStruct.new(success?: false, errors: [$!.message], exception: $!)
    end
  end

  def call!
    results = ActiveRecord::Base.transaction { _call! }
    OpenStruct.new(success?: true, results: results)
  end
end
