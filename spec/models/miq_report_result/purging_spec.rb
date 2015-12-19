describe MiqReportResult do
  context "::Purging" do
    before(:each) do
      @vmdb_config = {
        :reporting => {
          :history => {
            :keep_reports      => "6.months",
            :purge_window_size => 100
          }
        }
      }
      stub_server_configuration(@vmdb_config)

      @rr1 = [
        FactoryGirl.create(:miq_report_result, :miq_report_id => 1, :created_on => (6.months + 1.days).to_i.seconds.ago.utc),
        FactoryGirl.create(:miq_report_result, :miq_report_id => 1, :created_on => (6.months - 1.days).to_i.seconds.ago.utc)
      ]
      @rr2 = [
        FactoryGirl.create(:miq_report_result, :miq_report_id => 2, :created_on => (6.months + 2.days).to_i.seconds.ago.utc),
        FactoryGirl.create(:miq_report_result, :miq_report_id => 2, :created_on => (6.months + 1.days).to_i.seconds.ago.utc),
        FactoryGirl.create(:miq_report_result, :miq_report_id => 2, :created_on => (6.months - 1.days).to_i.seconds.ago.utc)
      ]
      @rr_orphaned = [
        FactoryGirl.create(:miq_report_result, :miq_report_id => nil, :created_on => (6.months - 1.days).to_i.seconds.ago.utc)
      ]
    end

    context "#purge_mode_and_value" do
      it "with missing config value" do
        @vmdb_config.delete_path(:reporting, :history, :keep_reports)
        Timecop.freeze(Time.now) do
          expect(described_class.purge_mode_and_value).to eq([:date, 6.months.to_i.seconds.ago.utc])
        end
      end

      it "with date" do
        @vmdb_config.store_path(:reporting, :history, :keep_reports, "1.day")
        Timecop.freeze(Time.now) do
          expect(described_class.purge_mode_and_value).to eq([:date, 1.day.to_i.seconds.ago.utc])
        end
      end

      it "with count" do
        @vmdb_config.store_path(:reporting, :history, :keep_reports, 50)
        expect(described_class.purge_mode_and_value).to eq([:remaining, 50])
      end
    end

    context "#purge_window_size" do
      it "with missing config value" do
        @vmdb_config.delete_path(:reporting, :history, :purge_window_size)
        Timecop.freeze(Time.now) do
          expect(described_class.purge_window_size).to eq(100)
        end
      end

      it "with value" do
        @vmdb_config.store_path(:reporting, :history, :purge_window_size, 1000)
        Timecop.freeze(Time.now) do
          expect(described_class.purge_window_size).to eq(1000)
        end
      end
    end

    it "#purge_timer" do
      EvmSpecHelper.create_guid_miq_server_zone

      Timecop.freeze(Time.now) do
        described_class.purge_timer

        q = MiqQueue.all
        expect(q.length).to eq(1)
        expect(q.first).to have_attributes(
          :class_name  => described_class.name,
          :method_name => "purge"
        )

        expect(q.first.args[0]).to eq(:date)
        expect(q.first.args[1]).to be_same_time_as 6.months.to_i.seconds.ago.utc
      end
    end

    context "#purge_queue" do
      before(:each) do
        EvmSpecHelper.create_guid_miq_server_zone
        described_class.purge_queue(:remaining, 1)
      end

      it "with nothing in the queue" do
        q = MiqQueue.all
        expect(q.length).to eq(1)
        expect(q.first).to have_attributes(
          :class_name  => described_class.name,
          :method_name => "purge",
          :args        => [:remaining, 1]
        )
      end

      it "with item already in the queue" do
        described_class.purge_queue(:remaining, 2)

        q = MiqQueue.all
        expect(q.length).to eq(1)
        expect(q.first).to have_attributes(
          :class_name  => described_class.name,
          :method_name => "purge",
          :args        => [:remaining, 2]
        )
      end
    end

    # private method - not sure if we need
    it "#purge_ids_for_remaining" do
      expect(described_class.send(:purge_ids_for_remaining, 1)).to eq({1 => @rr1.last.id, 2 => @rr2.last.id})
    end

    # private method - not sure if we need (and this is very expensive)
    it "#purge_counts_for_remaining" do
      expect(described_class.send(:purge_counts_for_remaining, 1)).to eq({1 => 1, 2 => 2})
    end

    context "#purge_count" do
      # private method - not sure who uses (and this is very expensive)
      it "by remaining" do
        expect(described_class.purge_count(:remaining, 1)).to eq(3)
      end

      it "by date" do
        expect(described_class.purge_count(:date, 6.months.to_i.seconds.ago.utc)).to eq(3)
      end
    end

    context "#purge" do
      it "by remaining" do
        described_class.purge(:remaining, 1)
        expect(described_class.where(:miq_report_id => 1)).to eq([@rr1.last])
        expect(described_class.where(:miq_report_id => 2)).to eq([@rr2.last])
        expect(described_class.where(:miq_report_id => nil)).to eq(@rr_orphaned)
      end

      it "by date" do
        described_class.purge(:date, 6.months.to_i.seconds.ago.utc)
        expect(described_class.where(:miq_report_id => 1)).to eq([@rr1.last])
        expect(described_class.where(:miq_report_id => 2)).to eq([@rr2.last])
        expect(described_class.where(:miq_report_id => nil)).to eq(@rr_orphaned)
      end
    end
  end
end
