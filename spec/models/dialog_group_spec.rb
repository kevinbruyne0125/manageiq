describe DialogGroup do
  let(:dialog_group) { FactoryGirl.build(:dialog_group, :label => 'group') }
  context "#validate_children" do
    it "fails without element" do
      expect { dialog_group.save! }
        .to raise_error(ActiveRecord::RecordInvalid, /Box group must have at least one Element/)
    end

    it "validates with at least one element" do
      dialog_group.dialog_fields << FactoryGirl.create(:dialog_field, :label => 'field 1', :name => 'field1')
      expect_any_instance_of(DialogField).to receive(:valid?)
      expect(dialog_group.errors.full_messages).to be_empty
      dialog_group.validate_children
    end
  end

  context "#dialog_fields" do
    # other tests are in dialog_spec.rb
    it "returns [] even when no dialog_tab" do
      expect(dialog_group.dialog_fields).to be_empty
    end
  end

  describe '#update_dialog_fields' do
    let(:dialog_fields) { FactoryGirl.create_list(:dialog_field, 2) }
    let(:dialog_group) { FactoryGirl.create(:dialog_group, :dialog_fields => dialog_fields) }

    context 'with an id' do
      let(:updated_fields) do
        [
          { 'id' => dialog_fields.first.id, 'label' => 'updated_field_label' },
          { 'id' => dialog_fields.last.id, 'label' => 'updated_field_label' }
        ]
      end

      it 'updates a dialog_field' do
        dialog_group.update_dialog_fields(updated_fields)

        dialog_group.reload
        expect(dialog_group.dialog_fields.first.label).to eq('updated_field_label')
        expect(dialog_group.dialog_fields.last.label).to eq('updated_field_label')
      end
    end

    context 'with a dialog_field removed' do
      let(:updated_fields) do
        [
          { 'id' => dialog_fields.first.id }
        ]
      end

      it 'deletes a dialog_field' do
        expect do
          dialog_group.update_dialog_fields(updated_fields)
        end.to change(dialog_group.reload.dialog_fields, :count).by(-1)
      end
    end

    context 'without an id' do
      let(:updated_fields) do
        [
          { 'id' => dialog_fields.first.id },
          { 'id' => dialog_fields.last.id },
          { 'name' => 'new field', 'label' => 'new field label' }
        ]
      end

      it 'adds a new dialog_field' do
        expect do
          dialog_group.update_dialog_fields(updated_fields)
        end.to change(dialog_group.reload.dialog_fields, :count).by(1)
      end
    end
  end
end
