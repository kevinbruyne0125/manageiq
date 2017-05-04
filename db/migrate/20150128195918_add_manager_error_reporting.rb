class AddManagerErrorReporting < ActiveRecord::Migration[4.2]
  def change
    add_column :configuration_managers, :last_refresh_error, :text
    add_column :configuration_managers, :last_refresh_date,  :timestamp
    add_column :provisioning_managers, :last_refresh_error, :text
    add_column :provisioning_managers, :last_refresh_date,  :timestamp
  end
end
