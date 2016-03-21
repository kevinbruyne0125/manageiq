class FloatingIpController < ApplicationController
  before_action :check_privileges
  before_action :get_session_data
  after_action :cleanup_action
  after_action :set_session_data

  include AuthorizationMessagesMixin
  include Mixins::GenericButtonMixin
  include Mixins::GenericListMixin
  include Mixins::GenericSessionMixin
  include Mixins::GenericShowMixin

  def self.display_methods
    %w()
  end

  def self.title
    _("Floating IPs")
  end
end
