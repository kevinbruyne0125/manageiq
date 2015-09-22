require "spec_helper"
require 'MiqContainerGroup/MiqContainerGroup'

describe ManageIQ::Providers::Kubernetes::ContainerManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq('kubernetes')
  end

  it ".raw_api_endpoint (ipv6)" do
    expect(described_class.raw_api_endpoint("::1", 123).to_s).to eq "https://[::1]:123"
  end

  context "SmartState Analysis Methods" do
    before(:each) do
      EvmSpecHelper.create_guid_miq_server_zone
      @ems = FactoryGirl.create(
        :ems_kubernetes,
        :hostname        => 'hostname',
        :authentications => [
          FactoryGirl.build(:authentication, :authtype => 'bearer', :auth_key => 'valid-token')
        ]
      )
    end

    it ".scan_entity_create" do
      entity = @ems.scan_entity_create(
        :pod_namespace => 'default',
        :pod_name      => 'name',
        :pod_port      => 8080,
        :guest_os      => 'GuestOS'
      )

      expect(entity).to be_kind_of(MiqContainerGroup)
      expect(entity.verify_mode).to eq(@ems.verify_ssl_mode)
      expect(entity.headers).to eq("Authorization" => "Bearer valid-token")
      expect(entity.guest_os).to eq('GuestOS')
    end

    it ".scan_job_create" do
      image = FactoryGirl.create(:container_image, :ext_management_system => @ems)
      job = @ems.scan_job_create(image.class.name, image.id)

      expect(job.state).to eq("waiting_to_start")
      expect(job.status).to eq("ok")
      expect(job.target_class).to eq(image.class.name)
      expect(job.target_id).to eq(image.id)
      expect(job.type).to eq(ManageIQ::Providers::Kubernetes::ContainerManager::Scanning::Job.name)
      expect(job.zone).to eq("default")
    end
  end
end
