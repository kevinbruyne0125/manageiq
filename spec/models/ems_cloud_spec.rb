require "spec_helper"

describe EmsCloud do
  it ".types" do
    expected_types = [ManageIQ::Providers::Amazon::CloudManager, EmsAzure, ManageIQ::Providers::Openstack::CloudManager].collect(&:ems_type)
    described_class.types.should match_array(expected_types)
  end

  it ".supported_subclasses" do
    expected_subclasses = [ManageIQ::Providers::Amazon::CloudManager, EmsAzure, ManageIQ::Providers::Openstack::CloudManager]
    described_class.supported_subclasses.should match_array(expected_subclasses)
  end

  it ".supported_types" do
    expected_types = [ManageIQ::Providers::Amazon::CloudManager, EmsAzure, ManageIQ::Providers::Openstack::CloudManager].collect(&:ems_type)
    described_class.supported_types.should match_array(expected_types)
  end

end
