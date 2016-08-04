class MiddlewareServerGroup < ApplicationRecord
  belongs_to :middleware_domain, :foreign_key => "domain_id"
  has_many :middleware_servers, :foreign_key => "server_group_id", :dependent => :destroy
  serialize :properties
end
