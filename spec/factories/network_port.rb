FactoryGirl.define do
  factory :network_port do
    sequence(:name)    { |n| "cloud_network_#{seq_padded_for_sorting(n)}" }
    sequence(:ems_ref) { |n| "ems_ref_#{seq_padded_for_sorting(n)}" }
  end

  factory :network_port_openstack, :class  => "ManageIQ::Providers::Openstack::NetworkManager::NetworkPort",
                                   :parent => :network_port
end
