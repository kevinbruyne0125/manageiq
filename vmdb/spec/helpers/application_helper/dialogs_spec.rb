require "spec_helper"

describe ApplicationHelper do
  context "::Dialogs" do
    describe "#dialog_dropdown_select_values" do

      before do
        val_array = [["cat", "Cat"], ["dog", "Dog"]]
        @val_array_reversed = val_array.collect(&:reverse)
        @field = DialogFieldDropDownList.new(:values => val_array)
      end

      it "not required" do
        @field.required = false
        values = helper.dialog_dropdown_select_values(@field, nil)
        values.should == [["<None>", nil]] + @val_array_reversed
      end

      it "required, nil selected" do
        @field.required = true
        values = helper.dialog_dropdown_select_values(@field, nil)
        values.should == [["<Choose>", nil]] + @val_array_reversed
      end

      it "required, non-nil selected" do
        @field.required = true
        values = helper.dialog_dropdown_select_values(@field, "cat")
        values.should == @val_array_reversed
      end
    end

    describe "#textbox_tag_options" do
      let(:dialog_field) { active_record_instance_double("DialogField", :id => "100", :read_only => read_only) }

      context "when the field is read_only" do
        let(:read_only) { true }

        it "returns the tag options with a disabled true" do
          expect(helper.textbox_tag_options(dialog_field, "url")).to eq({
            :maxlength => 50,
            :class     => "dynamic-text-box-100",
            :disabled  => true,
            :title     => "This element is disabled because it is read only"
          })
        end
      end

      context "when the dialog field is not read only" do
        let(:read_only) { false }

        it "returns the tag options with a data-miq-observe" do
          expect(helper.textbox_tag_options(dialog_field, "url")).to eq({
            :maxlength         => 50,
            :class             => "dynamic-text-box-100",
            "data-miq_observe" => "{\"interval\":\".5\",\"url\":\"url\"}"
          })
        end
      end
    end

    describe "#textarea_tag_options" do
      let(:dialog_field) { active_record_instance_double("DialogField", :id => "100", :read_only => read_only) }

      context "when the field is read_only" do
        let(:read_only) { true }

        it "returns the tag options with a disabled true" do
          expect(helper.textarea_tag_options(dialog_field, "url")).to eq({
            :class     => "dynamic-text-area-100",
            :maxlength => 8192,
            :size      => "50x6",
            :disabled  => true,
            :title     => "This element is disabled because it is read only"
          })
        end
      end

      context "when the dialog field is not read only" do
        let(:read_only) { false }

        it "returns the tag options with a data-miq-observe" do
          expect(helper.textarea_tag_options(dialog_field, "url")).to eq({
            :class             => "dynamic-text-area-100",
            :maxlength         => 8192,
            :size              => "50x6",
            "data-miq_observe" => "{\"interval\":\".5\",\"url\":\"url\"}"
          })
        end
      end
    end

    describe "#checkbox_tag_options" do
      let(:dialog_field) { active_record_instance_double("DialogField", :id => "100", :read_only => read_only) }

      context "when the field is read_only" do
        let(:read_only) { true }

        it "returns the tag options with a disabled true" do
          expect(helper.checkbox_tag_options(dialog_field, "url")).to eq({
            :class    => "dynamic-checkbox-100",
            :disabled => true,
            :title    => "This element is disabled because it is read only"
          })
        end
      end

      context "when the dialog field is not read only" do
        let(:read_only) { false }

        it "returns the tag options with a few data-miq attributes" do
          expect(helper.checkbox_tag_options(dialog_field, "url")).to eq({
            :class                      => "dynamic-checkbox-100",
            "data-miq_sparkle_on"       => true,
            "data-miq_sparkle_off"      => true,
            "data-miq_observe_checkbox" => "{\"url\":\"url\"}"
          })
        end
      end
    end

    describe "#date_tag_options" do
      let(:dialog_field) { active_record_instance_double("DialogField", :id => "100", :read_only => read_only) }

      context "when the field is read_only" do
        let(:read_only) { true }

        it "returns the tag options with a disabled true" do
          expect(helper.date_tag_options(dialog_field, "url")).to eq({
            :class    => "css1 dynamic-date-100",
            :readonly => "true",
            :disabled => true,
            :title    => "This element is disabled because it is read only"
          })
        end
      end

      context "when the dialog field is not read only" do
        let(:read_only) { false }

        it "returns the tag options with a few data-miq attributes" do
          expect(helper.date_tag_options(dialog_field, "url")).to eq({
            :class                  => "css1 dynamic-date-100",
            :readonly               => "true",
            "data-miq_observe_date" => "{\"url\":\"url\"}"
          })
        end
      end
    end

    describe "#time_tag_options" do
      let(:dialog_field) { active_record_instance_double("DialogField", :id => "100", :read_only => read_only) }

      context "when the field is read_only" do
        let(:read_only) { true }

        it "returns the tag options with a disabled true" do
          expect(helper.time_tag_options(dialog_field, "url", "hour_or_min")).to eq({
            :class    => "dynamic-date-hour_or_min-100",
            :disabled => true,
            :title    => "This element is disabled because it is read only"
          })
        end
      end

      context "when the dialog field is not read only" do
        let(:read_only) { false }

        it "returns the tag options with a few data-miq attributes" do
          expect(helper.time_tag_options(dialog_field, "url", "hour_or_min")).to eq({
            :class             => "dynamic-date-hour_or_min-100",
            "data-miq_observe" => "{\"url\":\"url\"}"
          })
        end
      end
    end

    describe "#drop_down_options" do
      let(:dialog_field) { active_record_instance_double("DialogField", :id => "100", :read_only => read_only) }

      context "when the field is read_only" do
        let(:read_only) { true }

        it "returns the tag options with a disabled true" do
          expect(helper.drop_down_options(dialog_field, "url")).to eq({
            :class    => "dynamic-drop-down-100",
            :disabled => true,
            :title    => "This element is disabled because it is read only"
          })
        end
      end

      context "when the dialog field is not read only" do
        let(:read_only) { false }

        it "returns the tag options with a few data-miq attributes" do
          expect(helper.drop_down_options(dialog_field, "url")).to eq({
            :class                 => "dynamic-drop-down-100",
            "data-miq_sparkle_on"  => true,
            "data-miq_sparkle_off" => true,
            "data-miq_observe"     => "{\"url\":\"url\"}"
          })
        end
      end
    end
  end
end
