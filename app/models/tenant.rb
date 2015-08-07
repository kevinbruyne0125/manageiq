class Tenant < ActiveRecord::Base
  HARDCODED_LOGO = "custom_logo.png"
  HARDCODED_LOGIN_LOGO = "custom_login_logo.png"
  DEFAULT_URL = nil

  default_value_for :company_name, "My Company"

  has_many :owned_providers,              :foreign_key => :tenant_owner_id, :class_name => 'Provider'
  has_many :owned_ext_management_systems, :foreign_key => :tenant_owner_id, :class_name => 'ExtManagementSystem'
  has_many :owned_vm_or_templates,        :foreign_key => :tenant_owner_id, :class_name => 'VmOrTemplate'

  has_many :tenant_resources
  has_many :vm_or_templates,
           :through     => :tenant_resources,
           :source      => :resource,
           :source_type => "VmOrTemplate"
  has_many :ext_management_systems,
           :through     => :tenant_resources,
           :source      => :resource,
           :source_type => "ExtManagementSystem"
  has_many :providers,
           :through     => :tenant_resources,
           :source      => :resource,
           :source_type => "Provider"

  has_many :miq_groups, :foreign_key => :tenant_owner_id
  has_many :users, :through => :miq_groups

  # FUTURE: /uploads/tenant/:id/logos/:basename.:extension # may want style
  has_attached_file :logo,
                    :url  => "/uploads/:basename.:extension",
                    :path => ":rails_root/public/uploads/:basename.:extension"

  has_attached_file :login_logo,
                    :url         => "/uploads/:basename.:extension",
                    :default_url => ":default_login_logo",
                    :path        => ":rails_root/public/uploads/:basename.:extension"

  validates :subdomain, :uniqueness => true, :allow_nil => true
  validates :domain,    :uniqueness => true, :allow_nil => true

  # FUTURE: allow more content_types
  validates_attachment_content_type :logo, :content_type => ['image/png']
  validates_attachment_content_type :login_logo, :content_type => ['image/png']

  # FUTURE: this is currently called session[:customer_name]. use this temporarily then remove
  alias_attribute :customer_name, :company_name
  # FUTURE: this is currently called session[:vmdb_name]. use this temporarily then remove
  alias_attribute :vmdb_name, :appliance_name

  before_save :nil_blanks

  # @return [Boolean] Is this a default tenant?
  def default?
    subdomain == DEFAULT_URL && domain == DEFAULT_URL
  end

  def logo?
    !!logo_file_name
  end

  def login_logo?
    !!login_logo_file_name
  end

  def self.default_tenant
    Tenant.find_by(:subdomain => DEFAULT_URL, :domain => DEFAULT_URL)
  end


  def self.seed
    Tenant.create_with(:company_name => nil).find_or_create_by(:subdomain => DEFAULT_URL, :domain => DEFAULT_URL)
  end

  private

  def nil_blanks
    self.subdomain = nil unless subdomain.present?
    self.domain = nil unless domain.present?

    self.company_name = nil unless company_name.present?
    self.appliance_name = nil unless appliance_name.present?
  end
end
