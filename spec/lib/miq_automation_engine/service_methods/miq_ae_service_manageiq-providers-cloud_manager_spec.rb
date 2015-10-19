require "spec_helper"

module MiqAeServiceEmsCloudSpec
  describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_CloudManager do
    it "#availability_zones" do
      described_class.instance_methods.should include(:availability_zones)
    end

    it "#cloud_networks" do
      described_class.instance_methods.should include(:cloud_networks)
    end

    it "#cloud_tenants" do
      described_class.instance_methods.should include(:cloud_tenants)
    end

    it "#flavors" do
      described_class.instance_methods.should include(:flavors)
    end

    it "#floating_ips" do
      described_class.instance_methods.should include(:floating_ips)
    end

    it "#key_pairs" do
      described_class.instance_methods.should include(:key_pairs)
    end

    it "#security_groups" do
      described_class.instance_methods.should include(:security_groups)
    end

    it "#cloud_resource_quotas" do
      described_class.instance_methods.should include(:cloud_resource_quotas)
    end

    it "#cloud_networks_public" do
      described_class.instance_methods.should include(:public_cloud_networks)
    end

    it "#cloud_networks_private" do
      described_class.instance_methods.should include(:private_cloud_networks)
    end
  end
end
