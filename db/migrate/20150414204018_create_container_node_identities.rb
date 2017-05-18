class CreateContainerNodeIdentities < ActiveRecord::Migration[4.2]
  def change
    # identity_infra is the node id assigned by the infrastructure
    add_column :container_nodes, :identity_infra, :string

    # identity_machine is the machine id generated by systemd:
    # http://www.freedesktop.org/software/systemd/man/machine-id.html
    add_column :container_nodes, :identity_machine, :string

    # identity_system is the system uuid collected by the bios, in
    # some infrastructure is injected by the hypervisor
    add_column :container_nodes, :identity_system, :string
  end
end
