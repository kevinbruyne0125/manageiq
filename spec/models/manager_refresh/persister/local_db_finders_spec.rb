require_relative '../helpers/spec_mocked_data'
require_relative '../helpers/spec_parsed_data'
require_relative 'test_persister'
require_relative 'targeted_refresh_spec_helper'

describe ManagerRefresh::Inventory::Persister do
  include SpecMockedData
  include SpecParsedData
  include TargetedRefreshSpecHelper

  ######################################################################################################################
  # Spec scenarios for making sure the local db index is able to build complex queries using references
  ######################################################################################################################
  #
  before :each do
    @zone = FactoryGirl.create(:zone)
    @ems  = FactoryGirl.create(:ems_cloud,
                               :zone            => @zone,
                               :network_manager => FactoryGirl.create(:ems_network, :zone => @zone))

    allow(@ems.class).to receive(:ems_type).and_return(:mock)
    allow(Settings.ems_refresh).to receive(:mock).and_return({})
  end

  before :each do
    initialize_mocked_records
  end

  let(:persister) { create_persister }

  context "check we can load network records from the DB" do
    it "finds in one batch after the scanning" do
      lazy_find_vm1        = persister.vms.lazy_find(:ems_ref => vm_data(1)[:ems_ref])
      lazy_find_vm2        = persister.vms.lazy_find(:ems_ref => vm_data(2)[:ems_ref])
      lazy_find_vm60       = persister.vms.lazy_find(:ems_ref => vm_data(60)[:ems_ref])
      lazy_find_hardware1  = persister.hardwares.lazy_find(:vm_or_template => lazy_find_vm1)
      lazy_find_hardware2  = persister.hardwares.lazy_find(:vm_or_template => lazy_find_vm2)
      lazy_find_hardware60 = persister.hardwares.lazy_find(:vm_or_template => lazy_find_vm60)

      lazy_find_network1  = persister.networks.lazy_find(
        {:hardware => lazy_find_hardware1, :description => "public"},
        :key     => :hostname,
        :default => 'default_value_unknown')
      lazy_find_network2  = persister.networks.lazy_find(
        {:hardware => lazy_find_hardware2, :description => "public"},
        :key     => :hostname,
        :default => 'default_value_unknown')
      lazy_find_network60 = persister.networks.lazy_find(
        {:hardware => lazy_find_hardware60, :description => "public"},
        :key     => :hostname,
        :default => 'default_value_unknown')

      @vm_data101 = vm_data(101).merge(
        :flavor           => persister.flavors.lazy_find(:ems_ref => flavor_data(1)[:name]),
        :genealogy_parent => persister.miq_templates.lazy_find(:ems_ref => image_data(1)[:ems_ref]),
        :key_pairs        => [persister.key_pairs.lazy_find(:name => key_pair_data(1)[:name])],
        :location         => lazy_find_network1,
      )

      @vm_data102 = vm_data(102).merge(
        :flavor           => persister.flavors.lazy_find(:ems_ref => flavor_data(1)[:name]),
        :genealogy_parent => persister.miq_templates.lazy_find(:ems_ref => image_data(1)[:ems_ref]),
        :key_pairs        => [persister.key_pairs.lazy_find(:name => key_pair_data(1)[:name])],
        :location         => lazy_find_network2,
      )

      @vm_data160 = vm_data(160).merge(
        :flavor           => persister.flavors.lazy_find(:ems_ref => flavor_data(1)[:name]),
        :genealogy_parent => persister.miq_templates.lazy_find(:ems_ref => image_data(1)[:ems_ref]),
        :key_pairs        => [persister.key_pairs.lazy_find(:name => key_pair_data(1)[:name])],
        :location         => lazy_find_network60,
      )

      persister.vms.build(@vm_data101)
      persister.vms.build(@vm_data102)
      persister.vms.build(@vm_data160)

      ManagerRefresh::InventoryCollection::Scanner.scan!(persister.inventory_collections)

      # Assert the local db index is empty if we do not load the reference
      expect(persister.networks.index_proxy.send(:local_db_indexes)[:manager_ref].send(:index)).to be_nil

      lazy_find_network1.load

      # Assert all references are loaded at once
      expect(persister.networks.index_proxy.send(:local_db_indexes)[:manager_ref].send(:index).keys).to(
        match_array(
          [
            "vm_ems_ref_1__public",
            "vm_ems_ref_2__public"
          ]
        )
      )

      expect(lazy_find_network1.load).to eq ("host_10_10_10_1.com")
      expect(lazy_find_network2.load).to eq ("host_10_10_10_2.com")
      expect(lazy_find_network60.load).to eq ("default_value_unknown")
    end

    it "finds one by one before we scan" do
      lazy_find_vm1        = persister.vms.lazy_find(:ems_ref => vm_data(1)[:ems_ref])
      lazy_find_vm2        = persister.vms.lazy_find(:ems_ref => vm_data(2)[:ems_ref])
      lazy_find_vm60       = persister.vms.lazy_find(:ems_ref => vm_data(60)[:ems_ref])
      lazy_find_hardware1  = persister.hardwares.lazy_find(:vm_or_template => lazy_find_vm1)
      lazy_find_hardware2  = persister.hardwares.lazy_find(:vm_or_template => lazy_find_vm2)
      lazy_find_hardware60 = persister.hardwares.lazy_find(:vm_or_template => lazy_find_vm60)
      # Assert the local db index is empty if we do not load the reference
      expect(persister.networks.index_proxy.send(:local_db_indexes)[:manager_ref].send(:index)).to be_nil

      network1 = persister.networks.lazy_find(:hardware => lazy_find_hardware1, :description => "public").load
      # Assert all references are one by one
      expect(persister.networks.index_proxy.send(:local_db_indexes)[:manager_ref].send(:index).keys).to(
        match_array(
          [
            "vm_ems_ref_1__public",
          ]
        )
      )
      network2 = persister.networks.find(:hardware => lazy_find_hardware2, :description => "public")
      expect(persister.networks.index_proxy.send(:local_db_indexes)[:manager_ref].send(:index).keys).to(
        match_array(
          [
            "vm_ems_ref_1__public",
            "vm_ems_ref_2__public"
          ]
        )
      )
      network60 = persister.networks.find(:hardware => lazy_find_hardware60, :description => "public")
      expect(persister.networks.index_proxy.send(:local_db_indexes)[:manager_ref].send(:index).keys).to(
        match_array(
          [
            "vm_ems_ref_1__public",
            "vm_ems_ref_2__public"
          ]
        )
      )

      # TODO(lsmola) known weakens, manager_uuid is wrong, but index is correct. So this doesn't affect a functionality
      # now, but it can be confusing
      expect(network1.manager_uuid).to eq "__public"
      expect(network2.manager_uuid).to eq "__public"
      expect(network60).to be_nil
    end
  end

  context "check secondary indexes on Vms" do

  end

  context "check secondary index with polymorphic relation inside" do
    it "will fail trying to build query using polymorphic column as index" do
      lazy_find_vm1 = persister.vms.lazy_find(:ems_ref => vm_data(1)[:ems_ref])

      # TODO(lsmola) Will we need to search by polymorphic columns? We do not do that now in any refresh. By design,
      # polymoprhic columns can't do join (they can, only for 1 table). Maybe union of 1 table joins using polymorphic
      # relations?
      # TODO(lsmola) We should probably assert this sooner? Now we are getting a failure trying to add :device in
      # .includes
      expect { persister.network_ports.lazy_find({:device => lazy_find_vm1}, :ref => :by_device).load }.to(
        raise_error(ActiveRecord::EagerLoadPolymorphicError,
                    "Cannot eagerly load the polymorphic association :device")
      )
    end
  end
end
