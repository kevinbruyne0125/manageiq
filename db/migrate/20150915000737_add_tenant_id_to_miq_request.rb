class AddTenantIdToMiqRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :miq_requests, :tenant_id, :bigint
    add_column :miq_request_tasks, :tenant_id, :bigint
    add_column :services, :tenant_id, :bigint
  end
end
