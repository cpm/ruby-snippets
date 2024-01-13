# frozen_string_literal: true

# BaseService assumes includer impements a `_call!` method with the following characteristics:
# 1. takes no arguments
# 2. raises on exceptions.
# 3. optionally returns something.
#
# BaseService exposes methods that returns a standard return object that looks like:
# => success? true|false
# => results: if successful, returns the results from `_call!`
# => errors: an array of error messages on failure
# => exception: the original exception that `_call!` used to bail
#
# in either case, will return a standard return object on success
# `call!`: if `_call!` throws: propogates the exception
#          else : returns standard return object
# `call`: always returns standard object, described above
#
# Also allows `call` and `call!` to be called directly on the class
# if initializer args are given. ie:
# => MyService.new(arg1, arg2, arg3).call == MyService.call(arg1, arg2, arg3)
module BaseService
  extend ActiveSupport::Concern
  include AfterCommitEverywhere

  class_methods do
    def call(*args, **kwargs)
      _call_with_normalized_kwargs(:call, *args, **kwargs)
    end

    def call!(*args, **kwargs)
      _call_with_normalized_kwargs(:call!, *args, **kwargs)
    end

    # sidekiq doesn't support named parameters, so if we have:
    # - named parameters required
    # - args has a hash for the last argument
    # - kwargs has nothing
    # we will assume `args.first` should be kwargs
    def _call_with_normalized_kwargs(method_name, *args, **kwargs)
      if instance_method(:initialize).parameters.present?
        if kwargs.blank? && args.last.kind_of?(Hash)
          kwargs = args.pop
        end
      end

      new(*args, **kwargs).send(method_name)
    end
  end

  def call
    begin
      call!
    rescue
      OpenStruct.new(success?: false, errors: [$!.message], exception: $!)
    end
  end

  def call!
    results = _call!
    OpenStruct.new(success?: true, results: results)
  end
end
