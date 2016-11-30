require_relative 'spec_helper'
require_relative 'spec_parsed_data'

describe ManagerRefresh::SaveInventory do
  include SpecHelper
  include SpecParsedData

  ######################################################################################################################
  #
  # Testing SaveInventory for directed acyclic graph (DAG) of the DtoCollection dependencies, testing that relations
  # are saved correctly for a testing set of DtoCollections whose dependencies look like:
  #
  #               +--------------+     +--------------+
  #               |              +----->              |
  #               |   KeyPair    |     |      VM      <------------+
  #               |              |  +-->              |            |
  #               +--------------+  |  +-------^------+            |
  #                                 |          |                   |
  #                                 |          |                   |
  #               +--------------+  |  +-------+------+     +------+-------+
  #               |              |  |  |              |     |              |
  #               |   Flavor     +--+  |   Hardware   +----->  MiqTemplate |
  #               |              |     |              |     |              |
  #               +--------------+     +----^---^-----+     +--------------+
  #                                         |   |
  #                                +--------+   +-------+
  #                                |                    |
  #                         +------+-------+     +------+-------+
  #                         |              |     |              |
  #                         |     Disk     |     |    Network   |
  #                         |              |     |              |
  #                         +--------------+     +--------------+
  #
  # The +--> marks a dependency, so Hardware +---> Vm means Hardware depends on Vm. So in this case, we need to make
  # sure Vm is saved to DB before Hardware does, since Hardware references Vm records
  #
  # The dependency of the DtoCollection is caused byt find or by lazy_find called on DtoCollection.
  #
  # Explanation of the lazy_find vs find:
  #
  # If we do lazy_find, it means DtoCollection can be empty at that time and this lazy_find is evaluated right before
  # the DtoCollections is saved. That means it doesn't depend on order how the DtoCollections are filled with data.
  # If we use find, the DtoCollection already needs to be filled with data, otherwise the find results with nil.
  #
  # Example of the dependency:
  #   the data of the DtoCollection for Hardware contains
  #
  #   @data[:vms].lazy_find(instance.id) or @data[:vms].find(instance.id)
  #
  #   This code results in LazyDto or Dto object, which we need to translate into Vm record, when we save Hardware
  #   record. Therefore, this depends on Vm being already saved in the DB,
  #
  # Example of the dependency using :key:
  #
  #   Using @data[:hardwares].lazy_find(instance.image_id, :key => :guest_os) we do not create a dependency, this code
  #   fetches an attribute :guest_os of the Hardware Dto, we do not create a dependency. The attribute is available
  #   before we save the Hardware DtoCollection.
  #
  #   But using @data[:hardwares].lazy_find(instance.image_id, :key => :vm_or_template), the attribute we are fetching
  #   is a record itself, that means we depend on the Hardware DtoCollection being saved.
  #
  ######################################################################################################################
  #
  # Test all settings for ManagerRefresh::SaveInventory
  [{:dto_saving_strategy => nil},
   {:dto_saving_strategy => :recursive},
  ].each do |dto_settings|
    context "with settings #{dto_settings}" do
      before :each do
        @zone = FactoryGirl.create(:zone)
        @ems  = FactoryGirl.create(:ems_cloud, :zone => @zone)

        allow(@ems.class).to receive(:ems_type).and_return(:mock)
        allow(Settings.ems_refresh).to receive(:mock).and_return(dto_settings)
      end

      context 'with empty DB' do
        before :each do
          initialize_data_and_dto_collections
        end

        it 'creates a graph of DtoCollections' do
          # Fill the DtoCollections with data
          add_data_to_dto_collection(@data[:vms], @vm_data_1, @vm_data_12, @vm_data_2, @vm_data_4)
          add_data_to_dto_collection(@data[:miq_templates], @image_data_1, @image_data_2, @image_data_3)
          add_data_to_dto_collection(@data[:key_pairs], @key_pair_data_1, @key_pair_data_12, @key_pair_data_2, @key_pair_data_3)
          add_data_to_dto_collection(@data[:hardwares], @hardware_data_1, @hardware_data_2, @hardware_data_12)
          add_data_to_dto_collection(@data[:disks], @disk_data_1, @disk_data_12, @disk_data_13, @disk_data_2)
          add_data_to_dto_collection(@data[:networks], @public_network_data_1, @public_network_data_12,
                                     @public_network_data_13, @public_network_data_14, @public_network_data_2)
          add_data_to_dto_collection(@data[:flavors], @flavor_data_1, @flavor_data_2, @flavor_data_3)

          # Invoke the DtoCollections saving
          ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

          # Assert saved data
          assert_full_dto_collections_graph

          assert_all_records_match_hashes(
            [Vm.all, @ems.vms],
            {
              :ems_ref  => "vm_ems_ref_1",
              :name     => "vm_name_1",
              :location => "host_10_10_10_1.com",
            }, {
              :ems_ref  => "vm_ems_ref_12",
              :name     => "vm_name_12",
              :location => "host_10_10_10_1.com",
            }, {
              :ems_ref  => "vm_ems_ref_2",
              :name     => "vm_name_2",
              :location => "host_10_10_10_2.com",
            }, {
              :ems_ref  => "vm_ems_ref_4",
              :name     => "vm_name_4",
              :location => "default_value_unknown",
            })
        end

        it 'creates and updates a graph of DtoCollections' do
          # Fill the DtoCollections with data
          add_data_to_dto_collection(@data[:vms], @vm_data_1, @vm_data_12, @vm_data_2, @vm_data_4)
          add_data_to_dto_collection(@data[:miq_templates], @image_data_1, @image_data_2, @image_data_3)
          add_data_to_dto_collection(@data[:key_pairs], @key_pair_data_1, @key_pair_data_12, @key_pair_data_2, @key_pair_data_3)
          add_data_to_dto_collection(@data[:hardwares], @hardware_data_1, @hardware_data_2, @hardware_data_12)
          add_data_to_dto_collection(@data[:disks], @disk_data_1, @disk_data_12, @disk_data_13, @disk_data_2)
          add_data_to_dto_collection(@data[:networks], @public_network_data_1, @public_network_data_12,
                                     @public_network_data_13, @public_network_data_14, @public_network_data_2)
          add_data_to_dto_collection(@data[:flavors], @flavor_data_1, @flavor_data_2, @flavor_data_3)

          # Invoke the DtoCollections saving
          ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

          # Assert that saved data have the updated values, checking id to make sure the original records are updated
          assert_full_dto_collections_graph

          assert_all_records_match_hashes(
            [Vm.all, @ems.vms],
            {
              :ems_ref  => "vm_ems_ref_1",
              :name     => "vm_name_1",
              :location => "host_10_10_10_1.com",
            }, {
              :ems_ref  => "vm_ems_ref_12",
              :name     => "vm_name_12",
              :location => "host_10_10_10_1.com",
            }, {
              :ems_ref  => "vm_ems_ref_2",
              :name     => "vm_name_2",
              :location => "host_10_10_10_2.com",
            }, {
              :ems_ref  => "vm_ems_ref_4",
              :name     => "vm_name_4",
              :location => "default_value_unknown",
            })

          # Fetch the created Vms from the DB, for comparing after second refresh
          vm1  = Vm.find_by(:ems_ref => "vm_ems_ref_1")
          vm12 = Vm.find_by(:ems_ref => "vm_ems_ref_12")
          vm2  = Vm.find_by(:ems_ref => "vm_ems_ref_2")
          vm4  = Vm.find_by(:ems_ref => "vm_ems_ref_4")

          # Second saving with the updated data
          # Fill the DtoCollections with data, that have a modified name
          initialize_data_and_dto_collections
          add_data_to_dto_collection(@data[:vms],
                                     @vm_data_1.merge(:name => "vm_name_1_changed"),
                                     @vm_data_12.merge(:name => "vm_name_12_changed"),
                                     @vm_data_2.merge(:name => "vm_name_2_changed"),
                                     @vm_data_4.merge(:name => "vm_name_4_changed"),
                                     vm_data(5))
          add_data_to_dto_collection(@data[:miq_templates], @image_data_1, @image_data_2, @image_data_3)
          add_data_to_dto_collection(@data[:key_pairs], @key_pair_data_1, @key_pair_data_12, @key_pair_data_2, @key_pair_data_3)
          add_data_to_dto_collection(@data[:hardwares], @hardware_data_1, @hardware_data_2, @hardware_data_12)
          add_data_to_dto_collection(@data[:disks], @disk_data_1, @disk_data_12, @disk_data_13, @disk_data_2)
          add_data_to_dto_collection(@data[:networks], @public_network_data_1, @public_network_data_12,
                                     @public_network_data_13, @public_network_data_14, @public_network_data_2)
          add_data_to_dto_collection(@data[:flavors], @flavor_data_1, @flavor_data_2, @flavor_data_3)

          # Invoke the DtoCollections saving
          ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

          # Assert saved data
          assert_full_dto_collections_graph
          # Assert that saved data have the updated values, checking id to make sure the original records are updated
          assert_all_records_match_hashes(
            [Vm.all, @ems.vms],
            {
              :id       => vm1.id,
              :ems_ref  => "vm_ems_ref_1",
              :name     => "vm_name_1_changed",
              :location => "host_10_10_10_1.com",
            }, {
              :id       => vm12.id,
              :ems_ref  => "vm_ems_ref_12",
              :name     => "vm_name_12_changed",
              :location => "host_10_10_10_1.com",
            }, {
              :id       => vm2.id,
              :ems_ref  => "vm_ems_ref_2",
              :name     => "vm_name_2_changed",
              :location => "host_10_10_10_2.com",
            }, {
              :id       => vm4.id,
              :ems_ref  => "vm_ems_ref_4",
              :name     => "vm_name_4_changed",
              :location => "default_value_unknown",
            }, {
              :id       => anything,
              :ems_ref  => "vm_ems_ref_5",
              :name     => "vm_name_5",
              :location => "vm_location_5",
            })
        end
      end
    end
  end

  def assert_full_dto_collections_graph
    vm1  = Vm.find_by(:ems_ref => "vm_ems_ref_1")
    vm12 = Vm.find_by(:ems_ref => "vm_ems_ref_12")
    vm2  = Vm.find_by(:ems_ref => "vm_ems_ref_2")
    vm4  = Vm.find_by(:ems_ref => "vm_ems_ref_4")

    expect(vm1.genealogy_parent).to(
      eq(ManageIQ::Providers::CloudManager::Template.find_by(:ems_ref => "image_ems_ref_1")))
    expect(vm12.genealogy_parent).to(
      eq(ManageIQ::Providers::CloudManager::Template.find_by(:ems_ref => "image_ems_ref_1")))
    expect(vm2.genealogy_parent).to(
      eq(ManageIQ::Providers::CloudManager::Template.find_by(:ems_ref => "image_ems_ref_2")))
    expect(vm4.genealogy_parent).to(eq(nil))

    expect(vm1.hardware.virtualization_type).to eq("virtualization_type_1")
    expect(vm1.hardware.disks.collect(&:device_name)).to match_array(["disk_name_1"])
    expect(vm1.hardware.networks.collect(&:ipaddress)).to match_array(["10.10.10.1"])

    expect(vm12.hardware.virtualization_type).to eq("virtualization_type_12")
    expect(vm12.hardware.disks.collect(&:device_name)).to match_array(["disk_name_12", "disk_name_13"])
    expect(vm12.hardware.networks.collect(&:ipaddress)).to match_array(["10.10.10.12", "10.10.10.13"])

    expect(vm2.hardware.virtualization_type).to eq("virtualization_type_2")
    expect(vm2.hardware.disks.collect(&:device_name)).to match_array(["disk_name_2"])
    expect(vm2.hardware.networks.collect(&:ipaddress)).to match_array(["10.10.10.2"])

    expect(vm4.hardware).to eq(nil)

    key_pair1  = ManageIQ::Providers::CloudManager::AuthKeyPair.find_by(:name => "key_pair_name_1")
    key_pair12 = ManageIQ::Providers::CloudManager::AuthKeyPair.find_by(:name => "key_pair_name_12")
    key_pair2  = ManageIQ::Providers::CloudManager::AuthKeyPair.find_by(:name => "key_pair_name_2")
    key_pair3  = ManageIQ::Providers::CloudManager::AuthKeyPair.find_by(:name => "key_pair_name_3")

    expect(vm1.key_pairs).to match_array([key_pair1])
    expect(vm12.key_pairs).to match_array([key_pair1, key_pair12])
    expect(vm2.key_pairs).to match_array([key_pair2])
    expect(vm4.key_pairs).to match_array(nil)

    expect(key_pair1.vms).to match_array([vm1, vm12])
    expect(key_pair12.vms).to match_array([vm12])
    expect(key_pair2.vms).to match_array([vm2])
    expect(key_pair3.vms).to match_array(nil)
  end

  def initialize_data_and_dto_collections
    # Initialize the DtoCollections
    @data                 = {}
    @data[:vms]           = ::ManagerRefresh::DtoCollection.new(
      ManageIQ::Providers::CloudManager::Vm,
      :parent      => @ems,
      :association => :vms)
    @data[:key_pairs]     = ::ManagerRefresh::DtoCollection.new(
      ManageIQ::Providers::CloudManager::AuthKeyPair,
      :parent      => @ems,
      :association => :key_pairs,
      :manager_ref => [:name])
    @data[:miq_templates] = ::ManagerRefresh::DtoCollection.new(
      ManageIQ::Providers::CloudManager::Template,
      :parent      => @ems,
      :association => :miq_templates)
    @data[:hardwares]     = ::ManagerRefresh::DtoCollection.new(
      Hardware,
      :parent      => @ems,
      :association => :hardwares,
      :manager_ref => [:vm_or_template])
    @data[:disks]         = ::ManagerRefresh::DtoCollection.new(
      Disk,
      :parent      => @ems,
      :association => :disks,
      :manager_ref => [:hardware, :device_name])
    @data[:networks]      = ::ManagerRefresh::DtoCollection.new(
      Network,
      :parent      => @ems,
      :association => :networks,
      :manager_ref => [:hardware, :description])
    @data[:flavors]       = ::ManagerRefresh::DtoCollection.new(
      Flavor,
      :parent      => @ems,
      :association => :flavors,
      :manager_ref => [:name])

    # Get parsed data with the lazy_relations
    @flavor_data_1        = flavor_data(1)
    @flavor_data_2        = flavor_data(2)
    @flavor_data_3        = flavor_data(3)

    @image_data_1 = image_data(1)
    @image_data_2 = image_data(2)
    @image_data_3 = image_data(3)

    @key_pair_data_1  = key_pair_data(1)
    @key_pair_data_12 = key_pair_data(12)
    @key_pair_data_2  = key_pair_data(2)
    @key_pair_data_3  = key_pair_data(3)

    @vm_data_1  = vm_data(1).merge(
      :flavor           => @data[:flavors].lazy_find(flavor_data(1)[:name]),
      :genealogy_parent => @data[:miq_templates].lazy_find(image_data(1)[:ems_ref]),
      :key_pairs        => [@data[:key_pairs].lazy_find(key_pair_data(1)[:name])],
      :location         => @data[:networks].lazy_find("#{vm_data(1)[:ems_ref]}__public",
                                                      :key     => :hostname,
                                                      :default => 'default_value_unknown'),
    )
    @vm_data_12 = vm_data(12).merge(
      :flavor           => @data[:flavors].lazy_find(flavor_data(1)[:name]),
      :genealogy_parent => @data[:miq_templates].lazy_find(image_data(1)[:ems_ref]),
      :key_pairs        => [@data[:key_pairs].lazy_find(key_pair_data(1)[:name]),
                            @data[:key_pairs].lazy_find(key_pair_data(12)[:name])],
      :location         => @data[:networks].lazy_find("#{vm_data(1)[:ems_ref]}__public",
                                                      :key     => :hostname,
                                                      :default => 'default_value_unknown'),
    )
    @vm_data_2  = vm_data(2).merge(
      :flavor           => @data[:flavors].lazy_find(flavor_data(2)[:name]),
      :genealogy_parent => @data[:miq_templates].lazy_find(image_data(2)[:ems_ref]),
      :key_pairs        => [@data[:key_pairs].lazy_find(key_pair_data(2)[:name])],
      :location         => @data[:networks].lazy_find("#{vm_data(2)[:ems_ref]}__public",
                                                      :key     => :hostname,
                                                      :default => 'default_value_unknown'),
    )
    @vm_data_4  = vm_data(4).merge(
      :flavor           => @data[:flavors].lazy_find(flavor_data(4)[:name]),
      :genealogy_parent => @data[:miq_templates].lazy_find(image_data(4)[:ems_ref]),
      :key_pairs        => [@data[:key_pairs].lazy_find(key_pair_data(4)[:name])].compact,
      :location         => @data[:networks].lazy_find("#{vm_data(4)[:ems_ref]}__public",
                                                      :key     => :hostname,
                                                      :default => 'default_value_unknown'),
    )

    @hardware_data_1  = hardware_data(1).merge(
      :guest_os       => @data[:miq_templates].lazy_find(image_data(1)[:ems_ref], :key => :guest_os),
      :vm_or_template => @data[:vms].lazy_find(vm_data(1)[:ems_ref])
    )
    @hardware_data_12 = hardware_data(12).merge(
      :guest_os       => @data[:miq_templates].lazy_find(image_data(1)[:ems_ref], :key => :guest_os),
      :vm_or_template => @data[:vms].lazy_find(vm_data(12)[:ems_ref])
    )
    @hardware_data_2  = hardware_data(2).merge(
      :guest_os       => @data[:miq_templates].lazy_find(image_data(2)[:ems_ref], :key => :guest_os),
      :vm_or_template => @data[:vms].lazy_find(vm_data(2)[:ems_ref])
    )

    @disk_data_1  = disk_data(1).merge(
      :hardware => @data[:hardwares].lazy_find(vm_data(1)[:ems_ref]),
    )
    @disk_data_12 = disk_data(12).merge(
      :hardware => @data[:hardwares].lazy_find(vm_data(12)[:ems_ref]),
    )
    @disk_data_13 = disk_data(13).merge(
      :hardware => @data[:hardwares].lazy_find(vm_data(12)[:ems_ref]),
    )
    @disk_data_2  = disk_data(2).merge(
      :hardware => @data[:hardwares].lazy_find(vm_data(2)[:ems_ref]),
    )

    @public_network_data_1  = public_network_data(1).merge(
      :hardware => @data[:hardwares].lazy_find(vm_data(1)[:ems_ref]),
    )
    @public_network_data_12 = public_network_data(12).merge(
      :hardware => @data[:hardwares].lazy_find(vm_data(12)[:ems_ref]),
    )
    @public_network_data_13 = public_network_data(13).merge(
      :hardware    => @data[:hardwares].lazy_find(vm_data(12)[:ems_ref]),
      :description => "public_2"
    )
    @public_network_data_14 = public_network_data(14).merge(
      :hardware    => @data[:hardwares].lazy_find(vm_data(12)[:ems_ref]),
      :description => "public_2" # duplicate key, network will be ignored
    )
    @public_network_data_2  = public_network_data(2).merge(
      :hardware => @data[:hardwares].lazy_find(vm_data(2)[:ems_ref]),
    )
  end
end
