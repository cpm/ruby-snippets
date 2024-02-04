# frozen_string_literal: true

# Abstract controller that includes all basic CRUD operations.
module DefaultJsonApiActions
  extend ActiveSupport::Concern

  include DefaultJsonApiIndexAction
  include DefaultJsonApiShowAction
  include DefaultJsonApiCreateAction
  include DefaultJsonApiUpdateAction
  include DefaultJsonApiDestroyAction
end
