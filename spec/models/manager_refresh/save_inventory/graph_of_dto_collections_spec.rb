require_relative 'spec_helper'
require_relative 'spec_parsed_data'

describe ManagerRefresh::SaveInventory do
  include SpecHelper
  include SpecParsedData

  ######################################################################################################################
  #
  # Testing SaveInventory for general graph of the DtoCollection dependencies, testing that relations
  # are saved correctly for a testing set of DtoCollections whose dependencies look like:
  #
  # 1. Example, cycle is stack -> stack
  #
  #                   +---------------+
  #                   |               <-----+
  #                   |     Stack     |     |
  #                   |               +-----+
  #                   +-------^-------+
  #                           |
  #                           |
  #                           |
  #                   +-------+-------+
  #                   |               |
  #                   |    Resource   |
  #                   |               |
  #                   +---------------+
  #
  # 2. Example, cycle is stack -> resource -> stack
  #
  #                   +---------------+
  #                   |               |
  #                   |     Stack     |
  #                   |               |
  #                   +---^------+----+
  #                       |      |
  #                       |      |
  #                       |      |
  #                   +---+------v----+
  #                   |               |
  #                   |    Resource   |
  #                   |               |
  #                   +---------------+
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
          initialize_dto_collections
        end

        it 'creates and updates a graph of DtoCollections with cycle stack -> stack' do
          # Doing 2 times, to make sure we first create all records then update all records
          2.times do
            # Fill the DtoCollections with data
            init_stack_data_with_stack_stack_cycle
            init_resource_data

            add_data_to_dto_collection(@data[:orchestration_stacks],
                                       @orchestration_stack_data_0_1,
                                       @orchestration_stack_data_0_2,
                                       @orchestration_stack_data_1_11,
                                       @orchestration_stack_data_1_12,
                                       @orchestration_stack_data_11_21,
                                       @orchestration_stack_data_12_22,
                                       @orchestration_stack_data_12_23)
            add_data_to_dto_collection(@data[:orchestration_stacks_resources],
                                       @orchestration_stack_resource_data_1_11,
                                       @orchestration_stack_resource_data_1_11_1,
                                       @orchestration_stack_resource_data_1_12,
                                       @orchestration_stack_resource_data_1_12_1,
                                       @orchestration_stack_resource_data_11_21,
                                       @orchestration_stack_resource_data_12_22,
                                       @orchestration_stack_resource_data_12_23)

            # Invoke the DtoCollections saving
            ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

            # Assert saved data
            assert_full_dto_collections_graph
          end
        end

        it 'creates and updates a graph of DtoCollections with cycle stack -> resource -> stack, through resource :key' do
          # Doing 2 times, to make sure we first create all records then update all records
          2.times do
            # Fill the DtoCollections with data
            init_stack_data_with_stack_resource_stack_cycle
            init_resource_data

            add_data_to_dto_collection(@data[:orchestration_stacks],
                                       @orchestration_stack_data_0_1,
                                       @orchestration_stack_data_0_2,
                                       @orchestration_stack_data_1_11,
                                       @orchestration_stack_data_1_12,
                                       @orchestration_stack_data_11_21,
                                       @orchestration_stack_data_12_22,
                                       @orchestration_stack_data_12_23)
            add_data_to_dto_collection(@data[:orchestration_stacks_resources],
                                       @orchestration_stack_resource_data_1_11,
                                       @orchestration_stack_resource_data_1_11_1,
                                       @orchestration_stack_resource_data_1_12,
                                       @orchestration_stack_resource_data_1_12_1,
                                       @orchestration_stack_resource_data_11_21,
                                       @orchestration_stack_resource_data_12_22,
                                       @orchestration_stack_resource_data_12_23)

            # Invoke the DtoCollections saving
            ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

            # Assert saved data
            assert_full_dto_collections_graph
          end
        end
      end

      context 'with empty DB and reversed DtoCollections' do
        before :each do
          initialize_dto_collections_reversed
        end

        it 'creates and updates a graph of DtoCollections with cycle stack -> stack' do
          # Doing 2 times, to make sure we first create all records then update all records
          2.times do
            # Fill the DtoCollections with data
            init_stack_data_with_stack_stack_cycle
            init_resource_data

            add_data_to_dto_collection(@data[:orchestration_stacks],
                                       @orchestration_stack_data_0_1,
                                       @orchestration_stack_data_0_2,
                                       @orchestration_stack_data_1_11,
                                       @orchestration_stack_data_1_12,
                                       @orchestration_stack_data_11_21,
                                       @orchestration_stack_data_12_22,
                                       @orchestration_stack_data_12_23)
            add_data_to_dto_collection(@data[:orchestration_stacks_resources],
                                       @orchestration_stack_resource_data_1_11,
                                       @orchestration_stack_resource_data_1_11_1,
                                       @orchestration_stack_resource_data_1_12,
                                       @orchestration_stack_resource_data_1_12_1,
                                       @orchestration_stack_resource_data_11_21,
                                       @orchestration_stack_resource_data_12_22,
                                       @orchestration_stack_resource_data_12_23)

            # Invoke the DtoCollections saving
            ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

            # Assert saved data
            assert_full_dto_collections_graph
          end
        end

        it 'creates and updates a graph of DtoCollections with cycle stack -> resource -> stack, through resource :key' do
          # Doing 2 times, to make sure we first create all records then update all records
          2.times do
            # Fill the DtoCollections with data
            init_stack_data_with_stack_resource_stack_cycle
            init_resource_data

            add_data_to_dto_collection(@data[:orchestration_stacks],
                                       @orchestration_stack_data_0_1,
                                       @orchestration_stack_data_0_2,
                                       @orchestration_stack_data_1_11,
                                       @orchestration_stack_data_1_12,
                                       @orchestration_stack_data_11_21,
                                       @orchestration_stack_data_12_22,
                                       @orchestration_stack_data_12_23)
            add_data_to_dto_collection(@data[:orchestration_stacks_resources],
                                       @orchestration_stack_resource_data_1_11,
                                       @orchestration_stack_resource_data_1_11_1,
                                       @orchestration_stack_resource_data_1_12,
                                       @orchestration_stack_resource_data_1_12_1,
                                       @orchestration_stack_resource_data_11_21,
                                       @orchestration_stack_resource_data_12_22,
                                       @orchestration_stack_resource_data_12_23)

            # Invoke the DtoCollections saving
            ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

            # Assert saved data
            assert_full_dto_collections_graph
          end
        end
      end

      context 'with the existing data in the DB' do
        it 'updates existing records with a graph of DtoCollections with cycle stack -> stack' do
          # Create all relations directly in DB
          initialize_mocked_records
          # And check the relations are correct
          assert_full_dto_collections_graph

          # Now we will update existing DB using SaveInventory
          # Fill the DtoCollections with data
          initialize_dto_collections
          init_stack_data_with_stack_stack_cycle
          init_resource_data

          add_data_to_dto_collection(@data[:orchestration_stacks],
                                     @orchestration_stack_data_0_1,
                                     @orchestration_stack_data_0_2,
                                     @orchestration_stack_data_1_11,
                                     @orchestration_stack_data_1_12,
                                     @orchestration_stack_data_11_21,
                                     @orchestration_stack_data_12_22,
                                     @orchestration_stack_data_12_23)
          add_data_to_dto_collection(@data[:orchestration_stacks_resources],
                                     @orchestration_stack_resource_data_1_11,
                                     @orchestration_stack_resource_data_1_11_1,
                                     @orchestration_stack_resource_data_1_12,
                                     @orchestration_stack_resource_data_1_12_1,
                                     @orchestration_stack_resource_data_11_21,
                                     @orchestration_stack_resource_data_12_22,
                                     @orchestration_stack_resource_data_12_23)

          # Invoke the DtoCollections saving
          ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

          # Assert saved data
          assert_full_dto_collections_graph

          # Check that we only updated the existing records
          orchestration_stack_0_1   = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_0_1")
          orchestration_stack_0_2   = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_0_2")
          orchestration_stack_1_11  = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_1_11")
          orchestration_stack_1_12  = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_1_12")
          orchestration_stack_11_21 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_11_21")
          orchestration_stack_12_22 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_12_22")
          orchestration_stack_12_23 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_12_23")

          orchestration_stack_resource_1_11   = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_1_11")
          orchestration_stack_resource_1_11_1 = OrchestrationStackResource.find_by(
            :ems_ref => "stack_resource_physical_resource_1_11_1")
          orchestration_stack_resource_1_12   = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_1_12")
          orchestration_stack_resource_1_12_1 = OrchestrationStackResource.find_by(
            :ems_ref => "stack_resource_physical_resource_1_12_1")
          orchestration_stack_resource_11_21  = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_11_21")
          orchestration_stack_resource_12_22  = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_12_22")
          orchestration_stack_resource_12_23  = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_12_23")

          expect(orchestration_stack_0_1).to eq(@orchestration_stack_0_1)
          expect(orchestration_stack_0_2).to eq(@orchestration_stack_0_2)
          expect(orchestration_stack_1_11).to eq(@orchestration_stack_1_11)
          expect(orchestration_stack_1_12).to eq(@orchestration_stack_1_12)
          expect(orchestration_stack_11_21).to eq(@orchestration_stack_11_21)
          expect(orchestration_stack_12_22).to eq(@orchestration_stack_12_22)
          expect(orchestration_stack_12_23).to eq(@orchestration_stack_12_23)

          expect(orchestration_stack_resource_1_11).to eq(@orchestration_stack_resource_1_11)
          expect(orchestration_stack_resource_1_11_1).to eq(@orchestration_stack_resource_1_11_1)
          expect(orchestration_stack_resource_1_12).to eq(@orchestration_stack_resource_1_12)
          expect(orchestration_stack_resource_1_12_1).to eq(@orchestration_stack_resource_1_12_1)
          expect(orchestration_stack_resource_11_21).to eq(@orchestration_stack_resource_11_21)
          expect(orchestration_stack_resource_12_22).to eq(@orchestration_stack_resource_12_22)
          expect(orchestration_stack_resource_12_23).to eq(@orchestration_stack_resource_12_23)
        end

        it 'updates existing records with a graph of DtoCollections with cycle stack -> resource -> stack, through resource :key' do
          # Create all relations directly in DB
          initialize_mocked_records
          # And check the relations are correct
          assert_full_dto_collections_graph

          # Now we will update existing DB using SaveInventory
          # Fill the DtoCollections with data
          initialize_dto_collections
          init_stack_data_with_stack_resource_stack_cycle
          init_resource_data

          add_data_to_dto_collection(@data[:orchestration_stacks],
                                     @orchestration_stack_data_0_1,
                                     @orchestration_stack_data_0_2,
                                     @orchestration_stack_data_1_11,
                                     @orchestration_stack_data_1_12,
                                     @orchestration_stack_data_11_21,
                                     @orchestration_stack_data_12_22,
                                     @orchestration_stack_data_12_23)
          add_data_to_dto_collection(@data[:orchestration_stacks_resources],
                                     @orchestration_stack_resource_data_1_11,
                                     @orchestration_stack_resource_data_1_11_1,
                                     @orchestration_stack_resource_data_1_12,
                                     @orchestration_stack_resource_data_1_12_1,
                                     @orchestration_stack_resource_data_11_21,
                                     @orchestration_stack_resource_data_12_22,
                                     @orchestration_stack_resource_data_12_23)

          # Invoke the DtoCollections saving
          ManagerRefresh::SaveInventory.save_inventory(@ems, @data)

          # Assert saved data
          assert_full_dto_collections_graph

          # Check that we only updated the existing records
          orchestration_stack_0_1   = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_0_1")
          orchestration_stack_0_2   = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_0_2")
          orchestration_stack_1_11  = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_1_11")
          orchestration_stack_1_12  = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_1_12")
          orchestration_stack_11_21 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_11_21")
          orchestration_stack_12_22 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_12_22")
          orchestration_stack_12_23 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_12_23")

          orchestration_stack_resource_1_11   = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_1_11")
          orchestration_stack_resource_1_11_1 = OrchestrationStackResource.find_by(
            :ems_ref => "stack_resource_physical_resource_1_11_1")
          orchestration_stack_resource_1_12   = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_1_12")
          orchestration_stack_resource_1_12_1 = OrchestrationStackResource.find_by(
            :ems_ref => "stack_resource_physical_resource_1_12_1")
          orchestration_stack_resource_11_21  = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_11_21")
          orchestration_stack_resource_12_22  = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_12_22")
          orchestration_stack_resource_12_23  = OrchestrationStackResource.find_by(
            :ems_ref => "stack_ems_ref_12_23")

          expect(orchestration_stack_0_1).to eq(@orchestration_stack_0_1)
          expect(orchestration_stack_0_2).to eq(@orchestration_stack_0_2)
          expect(orchestration_stack_1_11).to eq(@orchestration_stack_1_11)
          expect(orchestration_stack_1_12).to eq(@orchestration_stack_1_12)
          expect(orchestration_stack_11_21).to eq(@orchestration_stack_11_21)
          expect(orchestration_stack_12_22).to eq(@orchestration_stack_12_22)
          expect(orchestration_stack_12_23).to eq(@orchestration_stack_12_23)

          expect(orchestration_stack_resource_1_11).to eq(@orchestration_stack_resource_1_11)
          expect(orchestration_stack_resource_1_11_1).to eq(@orchestration_stack_resource_1_11_1)
          expect(orchestration_stack_resource_1_12).to eq(@orchestration_stack_resource_1_12)
          expect(orchestration_stack_resource_1_12_1).to eq(@orchestration_stack_resource_1_12_1)
          expect(orchestration_stack_resource_11_21).to eq(@orchestration_stack_resource_11_21)
          expect(orchestration_stack_resource_12_22).to eq(@orchestration_stack_resource_12_22)
          expect(orchestration_stack_resource_12_23).to eq(@orchestration_stack_resource_12_23)
        end
      end
    end
  end

  def assert_full_dto_collections_graph
    orchestration_stack_0_1   = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_0_1")
    orchestration_stack_0_2   = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_0_2")
    orchestration_stack_1_11  = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_1_11")
    orchestration_stack_1_12  = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_1_12")
    orchestration_stack_11_21 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_11_21")
    orchestration_stack_12_22 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_12_22")
    orchestration_stack_12_23 = OrchestrationStack.find_by(:ems_ref => "stack_ems_ref_12_23")

    orchestration_stack_resource_1_11   = OrchestrationStackResource.find_by(
      :ems_ref => "stack_ems_ref_1_11")
    orchestration_stack_resource_1_11_1 = OrchestrationStackResource.find_by(
      :ems_ref => "stack_resource_physical_resource_1_11_1")
    orchestration_stack_resource_1_12   = OrchestrationStackResource.find_by(
      :ems_ref => "stack_ems_ref_1_12")
    orchestration_stack_resource_1_12_1 = OrchestrationStackResource.find_by(
      :ems_ref => "stack_resource_physical_resource_1_12_1")
    orchestration_stack_resource_11_21  = OrchestrationStackResource.find_by(
      :ems_ref => "stack_ems_ref_11_21")
    orchestration_stack_resource_12_22  = OrchestrationStackResource.find_by(
      :ems_ref => "stack_ems_ref_12_22")
    orchestration_stack_resource_12_23  = OrchestrationStackResource.find_by(
      :ems_ref => "stack_ems_ref_12_23")

    expect(orchestration_stack_0_1.parent).to eq(nil)
    expect(orchestration_stack_0_2.parent).to eq(nil)
    expect(orchestration_stack_1_11.parent).to eq(orchestration_stack_0_1)
    expect(orchestration_stack_1_12.parent).to eq(orchestration_stack_0_1)
    expect(orchestration_stack_11_21.parent).to eq(orchestration_stack_1_11)
    expect(orchestration_stack_12_22.parent).to eq(orchestration_stack_1_12)
    expect(orchestration_stack_12_23.parent).to eq(orchestration_stack_1_12)

    expect(orchestration_stack_0_1.orchestration_stack_resources).to(
      match_array([orchestration_stack_resource_1_11,
                   orchestration_stack_resource_1_11_1,
                   orchestration_stack_resource_1_12,
                   orchestration_stack_resource_1_12_1]))
    expect(orchestration_stack_0_2.orchestration_stack_resources).to(
      match_array(nil))
    expect(orchestration_stack_1_11.orchestration_stack_resources).to(
      match_array([orchestration_stack_resource_11_21]))
    expect(orchestration_stack_1_12.orchestration_stack_resources).to(
      match_array([orchestration_stack_resource_12_22, orchestration_stack_resource_12_23]))
    expect(orchestration_stack_11_21.orchestration_stack_resources).to(
      match_array(nil))
    expect(orchestration_stack_12_22.orchestration_stack_resources).to(
      match_array(nil))
    expect(orchestration_stack_12_23.orchestration_stack_resources).to(
      match_array(nil))

    expect(orchestration_stack_resource_1_11.stack).to eq(orchestration_stack_0_1)
    expect(orchestration_stack_resource_1_11_1.stack).to eq(orchestration_stack_0_1)
    expect(orchestration_stack_resource_1_12.stack).to eq(orchestration_stack_0_1)
    expect(orchestration_stack_resource_1_12_1.stack).to eq(orchestration_stack_0_1)
    expect(orchestration_stack_resource_11_21.stack).to eq(orchestration_stack_1_11)
    expect(orchestration_stack_resource_12_22.stack).to eq(orchestration_stack_1_12)
    expect(orchestration_stack_resource_12_23.stack).to eq(orchestration_stack_1_12)
  end

  def initialize_dto_collections
    # Initialize the DtoCollections
    @data                                  = {}
    @data[:orchestration_stacks]           = ::ManagerRefresh::DtoCollection.new(
      ManageIQ::Providers::CloudManager::OrchestrationStack,
      :parent      => @ems,
      :association => :orchestration_stacks)
    @data[:orchestration_stacks_resources] = ::ManagerRefresh::DtoCollection.new(
      OrchestrationStackResource,
      :parent      => @ems,
      :association => :orchestration_stacks_resources)
  end

  def initialize_dto_collections_reversed
    # Initialize the DtoCollections in reversed order, so we know that untangling of the cycle does not depend on the
    # order of the DtoCollections
    @data                                  = {}
    @data[:orchestration_stacks_resources] = ::ManagerRefresh::DtoCollection.new(
      OrchestrationStackResource,
      :parent      => @ems,
      :association => :orchestration_stacks_resources)
    @data[:orchestration_stacks]           = ::ManagerRefresh::DtoCollection.new(
      ManageIQ::Providers::CloudManager::OrchestrationStack,
      :parent      => @ems,
      :association => :orchestration_stacks)
  end

  def init_stack_data_with_stack_stack_cycle
    @orchestration_stack_data_0_1   = orchestration_stack_data("0_1").merge(
      :parent => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_0")[:ems_ref]))
    @orchestration_stack_data_0_2   = orchestration_stack_data("0_2").merge(
      :parent => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_0")[:ems_ref]))
    @orchestration_stack_data_1_11  = orchestration_stack_data("1_11").merge(
      :parent => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_1")[:ems_ref]))
    @orchestration_stack_data_1_12  = orchestration_stack_data("1_12").merge(
      :parent => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_1")[:ems_ref]))
    @orchestration_stack_data_11_21 = orchestration_stack_data("11_21").merge(
      :parent => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("1_11")[:ems_ref]))
    @orchestration_stack_data_12_22 = orchestration_stack_data("12_22").merge(
      :parent => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("1_12")[:ems_ref]))
    @orchestration_stack_data_12_23 = orchestration_stack_data("12_23").merge(
      :parent => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("1_12")[:ems_ref]))
  end

  def init_stack_data_with_stack_resource_stack_cycle
    @orchestration_stack_data_0_1   = orchestration_stack_data("0_1").merge(
      :parent => @data[:orchestration_stacks_resources].lazy_find(orchestration_stack_data("0_1")[:ems_ref],
                                                                  :key => :stack)
    )
    @orchestration_stack_data_0_2   = orchestration_stack_data("0_2").merge(
      :parent => @data[:orchestration_stacks_resources].lazy_find(orchestration_stack_data("0_2")[:ems_ref],
                                                                  :key => :stack)
    )
    @orchestration_stack_data_1_11  = orchestration_stack_data("1_11").merge(
      :parent => @data[:orchestration_stacks_resources].lazy_find(orchestration_stack_data("1_11")[:ems_ref],
                                                                  :key => :stack)
    )
    @orchestration_stack_data_1_12  = orchestration_stack_data("1_12").merge(
      :parent => @data[:orchestration_stacks_resources].lazy_find(orchestration_stack_data("1_12")[:ems_ref],
                                                                  :key => :stack)
    )
    @orchestration_stack_data_11_21 = orchestration_stack_data("11_21").merge(
      :parent => @data[:orchestration_stacks_resources].lazy_find(orchestration_stack_data("11_21")[:ems_ref],
                                                                  :key => :stack)
    )
    @orchestration_stack_data_12_22 = orchestration_stack_data("12_22").merge(
      :parent => @data[:orchestration_stacks_resources].lazy_find(orchestration_stack_data("12_22")[:ems_ref],
                                                                  :key => :stack)
    )
    @orchestration_stack_data_12_23 = orchestration_stack_data("12_23").merge(
      :parent => @data[:orchestration_stacks_resources].lazy_find(orchestration_stack_data("12_23")[:ems_ref],
                                                                  :key => :stack)
    )
  end

  def init_resource_data
    @orchestration_stack_resource_data_1_11   = orchestration_stack_resource_data("1_11").merge(
      :ems_ref => orchestration_stack_data("1_11")[:ems_ref],
      :stack   => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_1")[:ems_ref]),
    )
    @orchestration_stack_resource_data_1_11_1 = orchestration_stack_resource_data("1_11_1").merge(
      :stack => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_1")[:ems_ref]),
    )
    @orchestration_stack_resource_data_1_12   = orchestration_stack_resource_data("1_12").merge(
      :ems_ref => orchestration_stack_data("1_12")[:ems_ref],
      :stack   => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_1")[:ems_ref]),
    )
    @orchestration_stack_resource_data_1_12_1 = orchestration_stack_resource_data("1_12_1").merge(
      :stack => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("0_1")[:ems_ref]),
    )
    @orchestration_stack_resource_data_11_21  = orchestration_stack_resource_data("11_21").merge(
      :ems_ref => orchestration_stack_data("11_21")[:ems_ref],
      :stack   => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("1_11")[:ems_ref]),
    )
    @orchestration_stack_resource_data_12_22  = orchestration_stack_resource_data("12_22").merge(
      :ems_ref => orchestration_stack_data("12_22")[:ems_ref],
      :stack   => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("1_12")[:ems_ref]),
    )
    @orchestration_stack_resource_data_12_23  = orchestration_stack_resource_data("12_23").merge(
      :ems_ref => orchestration_stack_data("12_23")[:ems_ref],
      :stack   => @data[:orchestration_stacks].lazy_find(orchestration_stack_data("1_12")[:ems_ref]),
    )
  end

  def initialize_mocked_records
    @orchestration_stack_0_1   = FactoryGirl.create(
      :orchestration_stack_cloud,
      orchestration_stack_data("0_1").merge(
        :ext_management_system => @ems,
        :parent                => nil))
    @orchestration_stack_0_2   = FactoryGirl.create(
      :orchestration_stack_cloud,
      orchestration_stack_data("0_2").merge(
        :ext_management_system => @ems,
        :parent                => nil))
    @orchestration_stack_1_11  = FactoryGirl.create(
      :orchestration_stack_cloud,
      orchestration_stack_data("1_11").merge(
        :ext_management_system => @ems,
        :parent                => @orchestration_stack_0_1))
    @orchestration_stack_1_12  = FactoryGirl.create(
      :orchestration_stack_cloud,
      orchestration_stack_data("1_12").merge(
        :ext_management_system => @ems,
        :parent                => @orchestration_stack_0_1))
    @orchestration_stack_11_21 = FactoryGirl.create(
      :orchestration_stack_cloud,
      orchestration_stack_data("11_21").merge(
        :ext_management_system => @ems,
        :parent                => @orchestration_stack_1_11))
    @orchestration_stack_12_22 = FactoryGirl.create(
      :orchestration_stack_cloud,
      orchestration_stack_data("12_22").merge(
        :ext_management_system => @ems,
        :parent                => @orchestration_stack_1_12))
    @orchestration_stack_12_23 = FactoryGirl.create(
      :orchestration_stack_cloud,
      orchestration_stack_data("12_23").merge(
        :ext_management_system => @ems,
        :parent                => @orchestration_stack_1_12))

    @orchestration_stack_resource_1_11   = FactoryGirl.create(
      :orchestration_stack_resource,
      orchestration_stack_resource_data("1_11").merge(
        :ems_ref => orchestration_stack_data("1_11")[:ems_ref],
        :stack   => @orchestration_stack_0_1,
      ))
    @orchestration_stack_resource_1_11_1 = FactoryGirl.create(
      :orchestration_stack_resource,
      orchestration_stack_resource_data("1_11_1").merge(
        :stack => @orchestration_stack_0_1,
      ))
    @orchestration_stack_resource_1_12   = FactoryGirl.create(
      :orchestration_stack_resource,
      orchestration_stack_resource_data("1_12").merge(
        :ems_ref => orchestration_stack_data("1_12")[:ems_ref],
        :stack   => @orchestration_stack_0_1,
      ))
    @orchestration_stack_resource_1_12_1 = FactoryGirl.create(
      :orchestration_stack_resource,
      orchestration_stack_resource_data("1_12_1").merge(
        :stack => @orchestration_stack_0_1,
      ))
    @orchestration_stack_resource_11_21  = FactoryGirl.create(
      :orchestration_stack_resource,
      orchestration_stack_resource_data("11_21").merge(
        :ems_ref => orchestration_stack_data("11_21")[:ems_ref],
        :stack   => @orchestration_stack_1_11,
      ))
    @orchestration_stack_resource_12_22  = FactoryGirl.create(
      :orchestration_stack_resource,
      orchestration_stack_resource_data("12_22").merge(
        :ems_ref => orchestration_stack_data("12_22")[:ems_ref],
        :stack   => @orchestration_stack_1_12,
      ))
    @orchestration_stack_resource_12_23  = FactoryGirl.create(
      :orchestration_stack_resource,
      orchestration_stack_resource_data("12_23").merge(
        :ems_ref => orchestration_stack_data("12_23")[:ems_ref],
        :stack   => @orchestration_stack_1_12,
      ))
  end
end
