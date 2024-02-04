# frozen_string_literal: true

module FastJsonable
  extend ActiveSupport::Concern

  protected

    def apply_simple_filters(scope, *filters)
      filters.each do |column|
        with_filter(column) do |values|
          scope = scope.where(column => values)
        end
      end

      return scope
    end

    def fjs(records:, serializer_klass: nil, includes_allowed: nil,
      meta: {}, params: {}, apply_current_institution: true
    )
      serializer_klass ||= fjs_serializer_klass
      included = fjs_active_includes(includes_allowed || fjs_includes_allowed)

      params[:active_storage] = params[:request] = {
        host: request.host,
        port: request.port,
        protocol: request.protocol
      }

      if apply_current_institution
        params[:controller] = {
          current_institution_id: current_institution&.id,
          current_convention_provider_id: current_institution&.convention_provider&.id,
        }
      end

      serializer_klass.new records,
        params: params,
        meta: meta,
        include: included
    end

    # this will resolve to SingluarControllerNameSerializer in current module.
    # override if naming doesn't line up
    def fjs_serializer_klass
      sprintf("%s::%sSerializer", 
        self.class.module_parent.to_s.singularize,
        controller_name.singularize.classify
      ).constantize
    end

    # filter out the includes such that action=index uses to params[:include]
    # and every other action. if controller has different rules, override
    def fjs_active_includes(includes)
      if action_name == "index"
        active_includes(includes)
      else
        includes
      end
    end

    # list of allowed jsonapi includes. override in your class
    def fjs_includes_allowed
      []
    end

    # give a list of includes params that are whitelisted
    def active_includes(allow_list)
      (params[:include] || "").split(",") & allow_list
    end
end
