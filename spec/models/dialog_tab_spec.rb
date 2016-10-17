describe DialogTab do
  let(:dialog_tab) { FactoryGirl.build(:dialog_tab, :label => 'tab') }
  context "#validate_children" do
    it "fails without box" do
      expect { dialog_tab.save! }
        .to raise_error(ActiveRecord::RecordInvalid, /tab must have at least one Box/)
    end

    it "validates with box" do
      dialog_tab.dialog_groups << FactoryGirl.create(:dialog_group, :label => 'box')
      expect_any_instance_of(DialogGroup).to receive(:valid?)
      expect(dialog_tab.errors.full_messages).to be_empty
      dialog_tab.validate_children
    end
  end

  context "#dialog_fields" do
    # other tests are in dialog_spec.rb
    it "returns [] even when no dialog_groups" do
      expect(dialog_tab.dialog_fields).to be_empty
    end

    it "returns [] when empty dialog_group " do
      dialog_tab.dialog_groups << FactoryGirl.build(:dialog_group)
      expect(dialog_tab.dialog_fields).to be_empty
    end
  end

  describe '#update_dialog_groups' do
    let(:dialog_fields) { FactoryGirl.create_list(:dialog_field, 2) }
    let(:dialog_groups) { FactoryGirl.create_list(:dialog_group, 2) }
    let(:dialog_tab) { FactoryGirl.create(:dialog_tab, :dialog_groups => dialog_groups) }

    before do
      dialog_groups.each_with_index { |group, index| group.dialog_fields << dialog_fields[index] }
    end

    context 'with an id' do
      let(:updated_groups) do
        [
          { 'id'            => dialog_groups.first.id,
            'label'         => 'updated_label',
            'dialog_fields' => [{ 'id' => dialog_fields.first.id}]},
          { 'id'            => dialog_groups.last.id,
            'label'         => 'updated_label',
            'dialog_fields' => [{'id' => dialog_fields.last.id}] }
        ]
      end

      it 'updates a dialog_group' do
        dialog_tab.update_dialog_groups(updated_groups)

        dialog_tab.reload

        expect(dialog_tab.dialog_groups.first.label).to eq('updated_label')
        expect(dialog_tab.dialog_groups.last.label).to eq('updated_label')
      end
    end

    context 'without an id' do
      let(:updated_groups) do
        [
          { 'id' => dialog_groups.first.id, 'dialog_fields' => [{'id' => dialog_fields.first.id}] },
          { 'id' => dialog_groups.last.id, 'dialog_fields' => [{'id' => dialog_fields.last.id}] },
          { 'label' => 'label', 'dialog_fields' => [{ 'name' => 'field name', 'label' => 'field name' }]}
        ]
      end

      it 'creates a new group' do
        expect do
          dialog_tab.update_dialog_groups(updated_groups)
        end.to change(dialog_tab.reload.dialog_groups, :count).by(1)
      end
    end

    context 'with a dialog_group removed' do
      let(:updated_groups) do
        [
          { 'id' => dialog_groups.first.id, 'dialog_fields' => []}
        ]
      end

      it 'deletes a dialog_group' do
        expect do
          dialog_tab.update_dialog_groups(updated_groups)
        end.to change(dialog_tab.reload.dialog_groups, :count).by(-1)
      end
    end
  end
end
