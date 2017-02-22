describe MiqReportResult do
  before :each do
    EvmSpecHelper.local_miq_server

    @user1 = FactoryGirl.create(:user_with_group)
  end

  it "#_async_generate_result" do
    task = FactoryGirl.create(:miq_task)
    EvmSpecHelper.local_miq_server
    report = MiqReport.create(
        :name          => "VMs based on Disk Type",
        :title         => "VMs using thin provisioned disks",
        :rpt_group     => "Custom",
        :rpt_type      => "Custom",
        :db            => "VmInfra",
        :cols          => ["name"],
        :col_order     => ["name"],
        :headers       => ["Name"],
        :order         => "Ascending",
        :template_type => "report"
    )
    report.generate_table(:userid => "admin")
    task.miq_report_result = report.build_create_results({:userid => "admin"}, task.id)
    task.miq_report_result._async_generate_result(task.id, :txt, :user => @user1)
    task.reload
    expect(task.state).to eq MiqTask::STATE_FINISHED
  end

  context "report result created by User 1 with current group 1" do
    before :each do
      @report_1 = FactoryGirl.create(:miq_report)
      group_1 = FactoryGirl.create(:miq_group)
      group_2 = FactoryGirl.create(:miq_group)
      @user1.miq_groups << group_1
      @report_result1 = FactoryGirl.create(:miq_report_result, :miq_report_id => @report_1.id, :miq_group => group_1)
      @report_result2 = FactoryGirl.create(:miq_report_result, :miq_report_id => @report_1.id, :miq_group => group_1)
      @report_result_nil_report_id = FactoryGirl.create(:miq_report_result)

      @report_2 = FactoryGirl.create(:miq_report)
      @report_result3 = FactoryGirl.create(:miq_report_result, :miq_report_id => @report_2.id, :miq_group => group_2)
      User.current_user = @user1
    end

    describe ".with_report" do
      it "returns report all results without nil report_id" do
        report_result = MiqReportResult.with_report
        expect(report_result).to match_array([@report_result1, @report_result2, @report_result3])
        expect(report_result).not_to include(@report_result_nil_report_id)
      end

      it "returns only requested report results" do
        report_result = MiqReportResult.with_report(@report_result1.miq_report_id)
        expect(report_result).to match_array([@report_result1, @report_result2])
        expect(report_result).not_to match_array([@report_result3, @report_result_nil_report_id])
      end
    end

    describe ".with_current_user_groups" do
      it "returns report results by generated by user 1, non-admin user logged" do
        report_result = MiqReportResult.with_current_user_groups
        expect(report_result).to match_array([@report_result1, @report_result2])
        expect(report_result).not_to match_array([@report_result3, @report_result_nil_report_id])
      end

      it "returns report all results, admin user logged" do
        admin_role = FactoryGirl.create(:miq_user_role, :name => "EvmRole-administrator", :read_only => false)
        User.current_user.current_group.miq_user_role = admin_role
        report_result = MiqReportResult.with_current_user_groups
        expected_reports = [@report_result1, @report_result2, @report_result3, @report_result_nil_report_id]
        expect(report_result).to match_array(expected_reports)
      end
    end
  end

  context "persisting generated report results" do
    before(:each) do
      5.times do |i|
        vm = FactoryGirl.build(:vm_vmware)
        vm.evm_owner_id = @user1.id               if i > 2
        vm.miq_group_id = @user1.current_group.id if vm.evm_owner_id || (i > 1)
        vm.save
      end

      @report_theme = 'miq'
      @show_title   = true
      @options = MiqReport.graph_options(600, 400)

      allow(Charting).to receive(:detect_available_plugin).and_return(C3Charting)
    end

    it "should save the original report metadata and the generated table as a binary blob" do
      MiqReport.seed_report(name = "Vendor and Guest OS")
      rpt = MiqReport.where(:name => name).last
      rpt.generate_table(:userid => "test")
      report_result = rpt.build_create_results(:userid => "test")

      report_result.reload

      expect(report_result).not_to be_nil
      expect(report_result.report.kind_of?(MiqReport)).to be_truthy
      expect(report_result.binary_blob).not_to be_nil
      expect(report_result.report_results.kind_of?(MiqReport)).to be_truthy
      expect(report_result.report_results.table).not_to be_nil
      expect(report_result.report_results.table.data).not_to be_nil
    end

    context "for miq_report_result is used different miq_group_id than user's current id" do
      before(:each) do
        MiqUserRole.seed
        role = MiqUserRole.find_by(:name => "EvmRole-operator")
        @miq_group = FactoryGirl.create(:miq_group, :miq_user_role => role, :description => "Group1")
        MiqReport.seed_report(@name_of_report = "Vendor and Guest OS")
      end

      it "has passed miq_group_id and not user's miq_group_id(can be changed during scheduling and generating)" do
        rpt = MiqReport.where(:name => @name_of_report).last
        rpt.generate_table(:userid => "test")
        report_result = rpt.build_create_results(:userid => "test", :miq_group_id => @miq_group.id) # passed group.id
        report_result.reload

        expect(@user1.current_group_id).not_to eq(@miq_group.id)
        expect(report_result.miq_group_id).to eq(@miq_group.id)
      end
    end
  end

  describe "serializing and deserializing report results" do
    it "can serialize and deserialize an MiqReport" do
      report = FactoryGirl.build(:miq_report)
      report_result = described_class.new

      report_result.report_results = report

      expect(report_result.report_results.to_hash).to eq(report.to_hash)
    end

    it "can serialize and deserialize a CSV" do
      csv = CSV.generate { |c| c << %w(foo bar) << %w(baz qux) }
      report_result = described_class.new

      report_result.report_results = csv

      expect(report_result.report_results).to eq(csv)
    end

    it "can serialize and deserialize a plain text report" do
      txt = <<EOF
+--------------+
|  Foo Report  |
+--------------+
| Foo  | Bar   |
+--------------+
| baz  | qux   |
| quux | corge |
+--------------+
EOF
      report_result = described_class.new

      report_result.report_results = txt

      expect(report_result.report_results).to eq(txt)
    end
  end

  describe ".counts_by_userid" do
    it "fetches counts" do
      u1 = FactoryGirl.create(:user)
      u2 = FactoryGirl.create(:user)
      FactoryGirl.create(:miq_report_result, :userid => u1.userid)
      FactoryGirl.create(:miq_report_result, :userid => u1.userid)
      FactoryGirl.create(:miq_report_result, :userid => u2.userid)

      expect(MiqReportResult.counts_by_userid).to match_array([
        {:userid => u1.userid, :count => 2},
        {:userid => u2.userid, :count => 1}
      ])
    end
  end
end
