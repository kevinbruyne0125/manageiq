require "spec_helper"

describe ManageIQ::Providers::Azure::CloudManager::Provision do
  let(:provider) { FactoryGirl.create(:ems_azure_with_authentication) }
  let(:template) { FactoryGirl.create(:template_azure, :ext_management_system => provider) }
  let(:flavor)   { FactoryGirl.create(:flavor_azure) }

  context "#create vm" do
    subscription_id = "01234567890"
    resource_group  = "test_resource_group"
    type            = "microsoft.resources"
    name            = "vm_1"
    nic_id          = "nic_id_1"

    before(:each) do
      subject.source = template
      allow(subject).to receive(:gather_storage_account_properties).and_return(%w("target_uri", "source_uri", "windows"))
      allow(subject).to receive(:create_nic).and_return(nic_id)
    end

    context "#find_destination_in_vmdb" do
      it "VM in same sub-class" do
        vm = FactoryGirl.create(:vm_azure, :ext_management_system => provider)
        expect(subject.find_destination_in_vmdb([subscription_id, resource_group, type, name])).to eq(vm)
      end

      it "VM in same sub-class with invalid parameters" do
        expect(subject.find_destination_in_vmdb(["invalid_subscription_id", resource_group, type, name])).to be_nil
      end

      it "VM in different sub-class" do
        vm = FactoryGirl.create(:vm_openstack, :ext_management_system => provider)
        vm.ems_ref = "openstack_vm"
        expect(subject.find_destination_in_vmdb([vm.ems_ref])).to be_nil
      end
    end

    context "#validate_dest_name" do
      let(:vm) { FactoryGirl.create(:vm_azure, :ext_management_system => provider) }

      it "with valid name" do
        allow(subject).to receive(:dest_name).and_return("new_vm_1")
        expect { subject.validate_dest_name }.to_not raise_error
      end

      it "with a blank name" do
        allow(subject).to receive(:dest_name).and_return("")
        expect { subject.validate_dest_name }.to raise_error
      end

      it "with a nil name" do
        allow(subject).to receive(:dest_name).and_return(nil)
        expect { subject.validate_dest_name }.to raise_error
      end

      it "with a duplicate name" do
        allow(subject).to receive(:dest_name).and_return(vm.name)
        expect { subject.validate_dest_name }.to raise_error
      end
    end

    context "#prepare_for_clone_task" do
      before do
        allow(subject).to receive(:instance_type).and_return(flavor)
      end

      context "nic settings" do
        it "with nic" do
          subject.options[:vm_target_name] = name
          expect(subject.prepare_for_clone_task[:properties][:networkProfile][:networkInterfaces][0][:id]).to eq(nic_id)
        end
      end
    end

    it "#workflow" do
      user    = FactoryGirl.create(:user)
      options = {:src_vm_id => [template.id, template.name]}
      vm_prov = FactoryGirl.create(:miq_provision_azure,
                                   :userid       => user.userid,
                                   :source       => template,
                                   :request_type => 'template',
                                   :state        => 'pending',
                                   :status       => 'Ok',
                                   :options      => options)

      workflow_class = ManageIQ::Providers::Azure::CloudManager::ProvisionWorkflow
      allow_any_instance_of(workflow_class).to receive(:get_dialogs).and_return(:dialogs => {})

      expect(vm_prov.workflow.class).to eq workflow_class
      expect(vm_prov.workflow_class).to eq workflow_class
    end
  end
end
