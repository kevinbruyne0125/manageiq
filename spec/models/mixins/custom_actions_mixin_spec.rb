describe CustomActionsMixin do
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      def self.name; "TestClass"; end
      self.table_name = "vms"
      include CustomActionsMixin
    end
  end

  describe '#custom_actions' do
    let(:definition) { FactoryGirl.create(:generic_object_definition) }
    let(:button) { FactoryGirl.create(:custom_button, :name => "generic_button", :applies_to_class => "GenericObject") }
    let(:group) { FactoryGirl.create(:custom_button_set, :name => "generic_button_group") }

    before { group.add_member(button) }

    context 'button group has only a hidden button' do
      before do
        allow(definition).to receive(:serialize_buttons_if_visible).and_return([])
      end

      it 'does not return with the button group' do
        expect(definition.custom_actions[:button_groups]).to be_empty
      end
    end

    it 'returns with the button group' do
      expect(definition.custom_actions[:button_groups]).not_to be_empty
    end
  end
end
