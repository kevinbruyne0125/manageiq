describe ChargebackContainerImage do
  let(:base_options) { {:interval_size => 2, :end_interval_offset => 0, :ext_options => {:tz => 'Pacific Time (US & Canada)'} } }
  let(:hourly_rate)       { 0.01 }
  let(:cpu_usage_rate)    { 50.0 }
  let(:cpu_count)         { 1.0 }
  let(:memory_available)  { 1000.0 }
  let(:memory_used)       { 100.0 }
  let(:net_usage_rate)    { 25.0 }
  let(:starting_date) { Time.zone.parse('2012-09-01 00:00:00 UTC') }
  let(:ts) { starting_date.in_time_zone(Metric::Helper.get_time_zone(options[:ext_options])) }
  let(:month_beginning) { ts.beginning_of_month.utc }
  let(:month_end) { ts.end_of_month.utc }
  let(:hours_in_month) { Time.days_in_month(month_beginning.month, month_beginning.year) * 24 }
  let(:ems) { FactoryGirl.create(:ems_openshift) }

  before do
    MiqRegion.seed
    ChargebackRate.seed

    EvmSpecHelper.create_guid_miq_server_zone
    @node = FactoryGirl.create(:container_node, :name => "node")
    @image = FactoryGirl.create(:container_image, :ext_management_system => ems)
    @label = FactoryGirl.build(:custom_attribute, :name => "version_label-1", :value => "1.0.0-rc_2", :section => 'docker_labels')
    @project = FactoryGirl.create(:container_project, :name => "my project", :ext_management_system => ems)
    @group = FactoryGirl.create(:container_group, :ext_management_system => ems, :container_project => @project,
                                :container_node => @node)
    @container = FactoryGirl.create(:kubernetes_container, :container_group => @group, :container_image => @image)
    cat = FactoryGirl.create(:classification, :description => "Environment", :name => "environment", :single_value => true, :show => true)
    c = FactoryGirl.create(:classification, :name => "prod", :description => "Production", :parent_id => cat.id)
    @cbr = FactoryGirl.create(:chargeback_rate, :rate_type => "compute")
    ChargebackRate.set_assignments(:compute, [{ :cb_rate => @cbr, :tag => [c, "container_image"] }])

    @tag = c.tag
    @project.tag_with(@tag.name, :ns => '*')
    @image.tag_with(@tag.name, :ns => '*')

    Timecop.travel(month_end)
  end

  after do
    Timecop.return
  end

  context "Daily" do
    let(:hours_in_day) { 24 }
    let(:options) { base_options.merge(:interval => 'daily', :entity_id => @project.id, :tag => nil) }

    before do

      ["2012-08-31T07:00:00Z", "2012-08-31T08:00:00Z", "2012-08-31T09:00:00Z", "2012-08-31T10:00:00Z"].each do |t|
        @container.metric_rollups << FactoryGirl.create(:metric_rollup_vm_hr,
                                                        :timestamp                => t,
                                                        :cpu_usage_rate_average   => cpu_usage_rate,
                                                        :derived_vm_numvcpus      => cpu_count,
                                                        :derived_memory_available => memory_available,
                                                        :derived_memory_used      => memory_used,
                                                        :net_usage_rate_average   => net_usage_rate,
                                                        :parent_ems_id            => ems.id,
                                                        :tag_names                => "",
                                                        :resource_name            => @project.name,
                                                        :resource_id              => @project.id)
        #state = VimPerformanceState.capture(@container)
        @container.vim_performance_states << FactoryGirl.create(:vim_performance_state,
                                                                :timestamp => t,
                                                                :image_tag_names => "environment/prod")
      end
    end

    subject { ChargebackContainerImage.build_results_for_report_ChargebackContainerImage(options).first.first }

    let(:cbt) {
      FactoryGirl.create(:chargeback_tier,
                         :start         => 0,
                         :finish        => Float::INFINITY,
                         :fixed_rate    => 0.0,
                         :variable_rate => hourly_rate.to_s)
    }
    let!(:cbrd) {
      FactoryGirl.create(:chargeback_rate_detail_fixed_compute_cost,
                         :chargeback_rate_id => @cbr.id,
                         :per_time           => "hourly",
                         :chargeback_tiers   => [cbt])
    }
    it "fixed_compute" do
      expect(subject.fixed_compute_1_cost).to eq(hourly_rate * hours_in_day)
    end
  end

  context "Monthly" do
    let(:options) { base_options.merge(:interval => 'monthly', :entity_id => @project.id, :tag => nil) }
    before do
      Range.new(month_beginning, month_end, true).step_value(12.hours).each do |time|
        @container.metric_rollups << FactoryGirl.create(:metric_rollup_vm_hr,
                                                        :timestamp                => time,
                                                        :cpu_usage_rate_average   => cpu_usage_rate,
                                                        :derived_vm_numvcpus      => cpu_count,
                                                        :derived_memory_available => memory_available,
                                                        :derived_memory_used      => memory_used,
                                                        :net_usage_rate_average   => net_usage_rate,
                                                        :parent_ems_id            => ems.id,
                                                        :tag_names                => "",
                                                        :resource_name            => @project.name,
                                                        :resource_id              => @project.id)
        @container.vim_performance_states << FactoryGirl.create(:vim_performance_state,
                                                                :timestamp => time,
                                                                :image_tag_names => "environment/prod")
      end
    end

    subject { ChargebackContainerImage.build_results_for_report_ChargebackContainerImage(options).first.first }

    let(:cbt) {
      FactoryGirl.create(:chargeback_tier,
                         :start         => 0,
                         :finish        => Float::INFINITY,
                         :fixed_rate    => 0.0,
                         :variable_rate => hourly_rate.to_s)
    }
    let!(:cbrd) {
      FactoryGirl.create(:chargeback_rate_detail_fixed_compute_cost,
                         :chargeback_rate_id => @cbr.id,
                         :per_time           => "hourly",
                         :chargeback_tiers   => [cbt])
    }
    it "fixed_compute" do
      # .to be_within(0.01) is used since theres a float error here
      expect(subject.fixed_compute_1_cost).to be_within(0.01).of(hourly_rate * hours_in_month)
    end
  end

  context "Label" do
    let(:options) { base_options.merge(:interval => 'monthly', :entity_id => @project.id, :tag => nil) }
    before do
      @image.docker_labels << @label
      ChargebackRate.set_assignments(:compute, [{ :cb_rate => @cbr, :label => [@label, "container_image"] }])

      Range.new(month_beginning, month_end, true).step_value(12.hours).each do |time|
        @container.metric_rollups << FactoryGirl.create(:metric_rollup_vm_hr,
                                                        :timestamp                => time,
                                                        :cpu_usage_rate_average   => cpu_usage_rate,
                                                        :derived_vm_numvcpus      => cpu_count,
                                                        :derived_memory_available => memory_available,
                                                        :derived_memory_used      => memory_used,
                                                        :net_usage_rate_average   => net_usage_rate,
                                                        :parent_ems_id            => ems.id,
                                                        :tag_names                => "",
                                                        :resource_name            => @project.name,
                                                        :resource_id              => @project.id)
        @container.vim_performance_states << FactoryGirl.create(:vim_performance_state,
                                                                :timestamp => time,
                                                                :image_tag_names => "")
      end
    end

    subject { ChargebackContainerImage.build_results_for_report_ChargebackContainerImage(options).first.first }

    let(:cbt) {
      FactoryGirl.create(:chargeback_tier,
                         :start         => 0,
                         :finish        => Float::INFINITY,
                         :fixed_rate    => 0.0,
                         :variable_rate => hourly_rate.to_s)
    }
    let!(:cbrd) {
      FactoryGirl.create(:chargeback_rate_detail_fixed_compute_cost,
                         :chargeback_rate_id => @cbr.id,
                         :per_time           => "hourly",
                         :source             => "compute_1",
                         :chargeback_tiers   => [cbt])
    }
    it "fixed_compute" do
      # .to be_within(0.01) is used since theres a float error here
      expect(subject.fixed_compute_1_cost).to be_within(0.01).of(hourly_rate * hours_in_month)
    end
  end
end
