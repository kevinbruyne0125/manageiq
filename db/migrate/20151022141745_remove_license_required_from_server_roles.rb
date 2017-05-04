class RemoveLicenseRequiredFromServerRoles < ActiveRecord::Migration[4.2]
  def up
    remove_column :server_roles, :license_required
  end

  def down
    add_column :server_roles, :license_required, :string
  end
end
