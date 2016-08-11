class MiddlewareDatasourceController < ApplicationController
  include EmsCommon
  include MiddlewareCommonMixin

  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  OPERATIONS = {
    :middleware_datasource_remove => { :op   => :remove_middleware_datasource,
                                       :hawk => N_('Not removed datasources'),
                                       :msg  => N_('The selected datasources were removed')
    }
  }.freeze

  def button
    selected_operation = params[:pressed].to_sym
    if OPERATIONS.key?(selected_operation)
      selected_ds = identify_selected_entities
      run_operation(OPERATIONS.fetch(selected_operation), selected_ds)
      javascript_flash
    else
      super
    end
  end
end
