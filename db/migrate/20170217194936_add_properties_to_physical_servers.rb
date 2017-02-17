class AddPropertiesToPhysicalServers < ActiveRecord::Migration[5.0]
  def change
    add_column :physical_servers, :hostname, :string
    add_column :physical_servers, :product_name, :string
    add_column :physical_servers, :manufacturer, :string
    add_column :physical_servers, :machine_type, :string
    add_column :physical_servers, :model, :string
    add_column :physical_servers, :serial_number, :string
    add_column :physical_servers, :uuid, :string, :index => true
    add_column :physical_servers, :field_replaceable_unit, :string
    add_column :physical_servers, :host_id, :bigint
  end
end
