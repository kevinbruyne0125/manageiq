FactoryGirl.define do
  factory :availability_zone do
    sequence(:name)     { |n| "availability_zone_#{seq_padded_for_sorting(n)}" }
  end

  factory :availability_zone_amazon, :parent => :availability_zone, :class => "ManageIQ::Providers::Amazon::CloudManager::AvailabilityZone" do
  end

  factory :availability_zone_openstack, :parent => :availability_zone, :class => "ManageIQ::Providers::Openstack::CloudManager::AvailabilityZone" do
  end

  factory :availability_zone_openstack_null, :parent => :availability_zone_openstack, :class => "ManageIQ::Providers::Openstack::CloudManager::AvailabilityZoneNull" do
  end

  factory :availability_zone_google, :parent => :availability_zone, :class => "ManageIQ::Providers::Google::CloudManager::AvailabilityZone" do
  end

  factory :availability_zone_target, :parent => :availability_zone do
    after(:create) do |x|
      x.perf_capture_enabled = true
    end
  end
end
