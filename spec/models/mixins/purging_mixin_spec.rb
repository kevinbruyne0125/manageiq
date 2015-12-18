describe PurgingMixin do
  let(:example_class) { PolicyEvent }
  let(:example_associated_class) { PolicyEventContent }
  let(:purge_date) { 2.weeks.ago }

  describe ".purge_date" do
    it "purge_date should not raise exception" do
      allow(example_class).to receive(:purge_config).with(:keep_policy_events).and_return(120)
      expect(example_class.purge_date).to be_within(1.second).of(120.seconds.ago.utc)
    end
  end

  describe ".purge" do
    let(:events) do
      (-2..2).collect do |date_modifier|
        FactoryGirl.create(:policy_event, :timestamp => purge_date + date_modifier.days)
      end
    end
    let(:all_ids) { events.collect(&:id) }
    let(:unpurged_ids) { all_ids[-2, 2] }

    it "with no records" do
      expect(example_class.purge(purge_date)).to eq(0)
    end

    it "with a date out of range" do
      events # create events
      expect(example_class.purge(6.months.ago)).to eq(0)
      expect(example_class.pluck(:id)).to match_array(all_ids)
    end

    it "with a date out of range" do
      events # create events
      allow(example_class).to receive(:purge_date).and_return(6.months.ago)
      expect(example_class.purge).to eq(0)
      expect(example_class.pluck(:id)).to match_array(all_ids)
    end

    it "with a date within range" do
      events # create events
      expect(example_class.purge(purge_date + 1.second)).to eq(3)
      expect(example_class.pluck(:id)).to match_array unpurged_ids
    end

    it "with a date within range from configuration" do
      events # create events
      allow(example_class).to receive(:purge_date).and_return(purge_date + 1.second)
      expect(example_class.purge).to eq(3)
      expect(example_class.pluck(:id)).to match_array unpurged_ids
    end

    it "with a date covering the whole range" do
      events # create events
      expect(example_class.purge(Time.now)).to eq(5)
      expect(example_class.pluck(:id)).to match_array []
    end

    it "with a date covering the whole range from configuration" do
      events # create events
      allow(example_class).to receive(:purge_date).and_return(Time.now)
      expect(example_class.purge(Time.now)).to eq(5)
      expect(example_class.pluck(:id)).to match_array []
    end

    it "with a date and a window" do
      events # create events
      expect(example_class.purge(purge_date + 1.second, 2)).to eq(2)
      expect(example_class.pluck(:id)).to match_array all_ids[-3, 3]
    end

    it "with a date and a window from configuration" do
      events # create events
      allow(example_class).to receive(:purge_date).and_return(purge_date + 1.second)
      allow(example_class).to receive(:purge_window_size).and_return(2)
      expect(example_class.purge).to eq(2)
      expect(example_class.pluck(:id)).to match_array all_ids[-3, 3]
    end
  end
end
