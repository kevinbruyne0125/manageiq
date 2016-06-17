describe DialogFieldVisibilityService do
  let(:subject) { described_class.new }

  describe "#determine_visibility" do
    let(:subject) do
      described_class.new(
        auto_placement_visibility_service,
        number_of_vms_visibility_service,
      )
    end

    let(:options) do
      {
        :auto_placement_enabled          => auto_placement_enabled,
        :number_of_vms                   => number_of_vms,
        :platform                        => platform,
      }
    end

    let(:auto_placement_visibility_service) { double("AutoPlacementVisibilityService") }
    let(:auto_placement_enabled) { "auto_placement_enabled" }

    let(:number_of_vms_visibility_service) { double("NumberOfVmsVisibilityService") }
    let(:number_of_vms) { "number_of_vms" }
    let(:platform) { "platform" }

    before do
      allow(auto_placement_visibility_service).
        to receive(:determine_visibility).with(auto_placement_enabled).and_return(
          {:hide => [:auto_hide], :show => [:auto_show]}
        )
      allow(number_of_vms_visibility_service).
        to receive(:determine_visibility).with(number_of_vms, platform).and_return(
          {:hide => [:number_hide], :show => [:number_show]}
        )
    end

    it "adds the values to the field names to hide and show without duplicates or intersections" do
      expect(subject.determine_visibility(options)).to eq({
        :hide => [
          :auto_hide,
          :number_hide
        ],
        :edit => [
          :auto_show,
          :number_show
        ]
      })
    end
  end
end
