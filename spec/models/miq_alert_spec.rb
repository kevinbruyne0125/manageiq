describe MiqAlert do
  context "With single server with a single generic worker with the notifier role," do
    before(:each) do
      @miq_server = EvmSpecHelper.local_miq_server(:role => 'notifier')
      @worker = FactoryGirl.create(:miq_worker, :miq_server_id => @miq_server.id)
      @vm     = FactoryGirl.create(:vm_vmware)

      MiqAlert.seed
      @events_to_alerts = MiqAlert.all.inject([]) do |arr, a|
        next(arr) if a.responds_to_events.nil?
        next(arr) unless a.db == "Vm"

        ap = FactoryGirl.create(:miq_alert_set, :description => "Alert Profile for #{a.id}", :mode => @vm.class.base_model.name)
        ap.add_member(a)
        ap.assign_to_objects(@vm)

        events = a.responds_to_events.split(",")
        events.each do |e|
          event = e.strip
          arr << [event, a.guid]
        end
        arr
      end
    end

    context "where a vm_scan_complete event is raised for a VM" do
      before(:each) do
        MiqAlert.all.each { |a| a.update_attribute(:enabled, true) } # enable out of the box alerts
        MiqAlert.evaluate_alerts(@vm, "vm_scan_complete")
      end

      it "should alert 'VM Guest Windows Event Log Error - NtpClient' should be evaluated" do
        msg = MiqQueue.get(:role => "notifier")
        expect(msg).not_to be_nil

        alert = MiqAlert.find_by_id(msg.instance_id)
        expect(alert).not_to be_nil
        expect(alert.description).to eq('VM Guest Windows Event Log Error - NtpClient')
      end
    end

    context "where a vm_scan_complete event is raised for a VM" do
      before(:each) do
        MiqAlert.all.each { |a| a.update_attribute(:enabled, true) } # enable out of the box alerts

        @events_to_alerts.each do |arr|
          MiqAlert.evaluate_alerts([@vm.class.base_class.name, @vm.id], arr.first)
        end
      end

      it "should queue up the correct alert for each event" do
        guids = @events_to_alerts.collect(&:last).uniq
        messages = MiqQueue.order("id")
        expect(messages.length).to eq(@events_to_alerts.length)

        messages.each_with_index do |msg, i|
          alert = MiqAlert.find_by(:id => msg.instance_id)
          expect(alert).not_to be_nil

          event, guid = @events_to_alerts[i]
          expect(guids.include?(alert.guid)).to be_truthy
        end
      end
    end

    context "where all alerts are disabled" do
      before(:each) do
        MiqAlert.evaluate_alerts([@vm.class.base_class.name, @vm.id], "vm_scan_complete")
      end

      it "should not evaluate any alerts" do
        @msg = MiqQueue.get(:role => "notifier")
        expect(@msg).to be_nil
      end
    end

    context "with a single alert, not evaluated" do
      before(:each) do
        @alert = MiqAlert.find_by_description("VM Unregistered")
      end

      context "with a delay_next_evaluation value of 5 minutes" do
        before(:each) do
          @alert.options ||= {}
          @alert.options.store_path(:notifications, :delay_next_evaluation, 5.minutes)
        end

        it "should always perform evaluation if not previously evaluated (after 4 minutes)" do
          Timecop.travel 4.minutes do
            expect(@alert.postpone_evaluation?(@vm)).to be_falsey
          end
        end
      end
    end

    context "with a single alert, evaluated to true" do
      before(:each) do
        @alert = MiqAlert.find_by_description("VM Unregistered")
        allow(@alert).to receive_messages(:eval_expression => true)
        @alert.evaluate([@vm.class.base_class.name, @vm.id])
      end

      it "should have a link from the MiqAlert to the miq alert status" do
        expect(@alert.miq_alert_statuses.where(:resource_type => @vm.class.base_class.name, :resource_id => @vm.id).count).to eq(1)
      end

      it "should have a miq alert status for MiqAlert with a result of true" do
        expect(@alert.miq_alert_statuses.find_by(:resource_type => @vm.class.base_class.name, :resource_id => @vm.id).result).to be_truthy
      end

      it "should have a link from the Vm to the miq alert status" do
        expect(@vm.miq_alert_statuses.where(:miq_alert_id => @alert.id).count).to eq(1)
      end

      it "should have a miq alert status for Vm with a result of true" do
        expect(@vm.miq_alert_statuses.find_by(:miq_alert_id => @alert.id).result).to be_truthy
      end

      context "with the alert now evaluated to false" do
        before(:each)  do
          allow(@alert).to receive_messages(:eval_expression => false)
          @alert.options.store_path(:notifications, :delay_next_evaluation, 0)
          @alert.evaluate([@vm.class.base_class.name, @vm.id])
        end

        it "should have had the MiqAlert's miq_alert_statuses" do
          expect(@alert.miq_alert_statuses.where(:resource_type => @vm.class.base_class.name, :resource_id => @vm.id).count).to eq(1)
        end

        it "should have a miq alert status for MiqAlert with a result of false" do
          expect(@alert.miq_alert_statuses.find_by(:resource_type => @vm.class.base_class.name, :resource_id => @vm.id).result).to be_falsey
        end

        it "should have the Vm's miq_alert_statuses" do
          expect(@vm.miq_alert_statuses.where(:miq_alert_id => @alert.id).count).to eq(1)
        end

        it "should have a miq alert status for Vm with a result of false" do
          expect(@vm.miq_alert_statuses.find_by(:miq_alert_id => @alert.id).result).to be_falsey
        end
      end

      context "with a delay_next_evaluation value of 5 minutes" do
        before(:each) do
          @alert.options ||= {}
          @alert.options.store_path(:notifications, :delay_next_evaluation, 5.minutes)
          @alert.save
        end

        it "should retry evaluation (after 10 minutes)" do
          Timecop.travel 10.minutes do
            expect(@alert.postpone_evaluation?(@vm)).to be_falsey
          end
        end

        it "should skip evaluation (after 4 minutes)" do
          Timecop.travel 4.minutes do
            expect(@alert.postpone_evaluation?(@vm)).to be_truthy
          end
        end
      end
    end

    context "where all alerts are unassigned" do
      before(:each) do
        MiqAlert.all.each { |a| a.update_attribute(:enabled, true) } # enable out of the box alerts
        @original_assigned     = MiqAlert.assigned_to_target(@vm, "vm_perf_complete") # force cache load
        @original_assigned_all = MiqAlert.assigned_to_target(@vm)                     # force cache load
        MiqAlertSet.all.each(&:remove_all_assigned_tos)

        @assigned_now     = MiqAlert.assigned_to_target(@vm, "vm_perf_complete")
        @assigned_all_now = MiqAlert.assigned_to_target(@vm)

        Timecop.travel(6.minutes) do
          @assigned_later     = MiqAlert.assigned_to_target(@vm, "vm_perf_complete")
          @assigned_all_later = MiqAlert.assigned_to_target(@vm)
        end
      end

      it "should still have alerts assigned to vm now" do
        expect(@assigned_now.length).to eq(@original_assigned.length)
        expect(@assigned_all_now.length).to eq(@original_assigned_all.length)
      end

      it "should not have any alerts assigned to vm later" do
        expect(@assigned_later.length).to eq(0)
        expect(@assigned_all_later.length).to eq(0)
      end
    end
  end

  context ".assigned_to_target" do
    before do
      cat = FactoryGirl.create(:classification, :description => "Environment", :name => "environment",  :single_value => true,  :parent_id => 0)
      FactoryGirl.create(:classification, :name => "prod", :description => "Production", :parent_id => cat.id)

      @vm   = FactoryGirl.create(:vm_vmware)
      @mode = @vm.class.base_model.name
      @c    = Classification.where(:description => "Production").first
      @c.assign_entry_to(@vm)

      @alert = FactoryGirl.create(:miq_alert_vm,  :description => "Alert Testing", :enabled => true)
      @ap    = FactoryGirl.create(:miq_alert_set, :description => "Alert Profile for #{@alert.id}", :mode => @mode)
      @ap.add_member(@alert)
      @ap.assign_to_tags([@c.id], @mode)
    end

    it "should get assignment by tagged VM" do
      expect(MiqAlert.assigned_to_target(@vm)).to eq([@alert])
    end
  end

  context "With a VM assigned to a realtime C&U alert" do
    before(:each) do
      allow_any_instance_of(MiqAlert).to receive_messages(:validate => true)
      @vm         = FactoryGirl.create(:vm_vmware)
      @alert      = FactoryGirl.create(:miq_alert, :enabled => true, :db => "Vm", :responds_to_events => "xxx|vm_perf_complete|zzz")
      @alert_prof = FactoryGirl.create(:miq_alert_set, :description => "Alert Profile for Alert Id: #{@alert.id}", :mode => @vm.class.base_model.name)
      @alert_prof.add_member(@alert)
      @alert_prof.assign_to_objects(@vm)
    end

    it "should return true when calling target_needs_realtime_capture?" do
      expect(MiqAlert.target_needs_realtime_capture?(@vm)).to be_truthy
    end
  end

  context "With a VM NOT assigned to a realtime C&U alert" do
    before(:each) do
      allow_any_instance_of(MiqAlert).to receive_messages(:validate => true)
      @vm     = FactoryGirl.create(:vm_vmware)
    end

    it "should return false when calling target_needs_realtime_capture?" do
      expect(MiqAlert.target_needs_realtime_capture?(@vm)).to be_falsey
    end
  end

  context "With a Host assigned to a realtime C&U alert" do
    before(:each) do
      allow_any_instance_of(MiqAlert).to receive_messages(:validate => true)
      @host     = FactoryGirl.create(:host)
      @alert    = FactoryGirl.create(:miq_alert, :enabled => true, :db => "Host", :responds_to_events => "xxx|host_perf_complete|zzz")
      @alert_prof = FactoryGirl.create(:miq_alert_set, :description => "Alert Profile for Alert Id: #{@alert.id}", :mode => @host.class.base_model.name)
      @alert_prof.add_member(@alert)
      @alert_prof.assign_to_objects(@host)
    end

    it "should return true when calling target_needs_realtime_capture?" do
      expect(MiqAlert.target_needs_realtime_capture?(@host)).to be_truthy
    end
  end

  context "With a Host NOT assigned to a realtime C&U alert" do
    before(:each) do
      allow_any_instance_of(MiqAlert).to receive_messages(:validate => true)
      @host     = FactoryGirl.create(:host)
    end

    it "should return false when calling target_needs_realtime_capture?" do
      expect(MiqAlert.target_needs_realtime_capture?(@host)).to be_falsey
    end
  end

  context "With a VM assigned to a v4-style realtime C&U alert" do
    before(:each) do
      allow_any_instance_of(MiqAlert).to receive_messages(:validate => true)
      @vm         = FactoryGirl.create(:vm_vmware)
      @alert      = FactoryGirl.create(:miq_alert, :enabled => true, :db => "Vm", :responds_to_events => "xxx|vm_perf_complete|zzz")
      @alert_prof = FactoryGirl.create(:miq_alert_set, :description => "Alert Profile for Alert Id: #{@alert.id}", :mode => @vm.class.base_model.name)
      @alert_prof.add_member(@alert)
      # V4 code is actually the same here -- assign_to_objects -- but
      # this forces the namespace to use actual model class name
      # rather than base_class
      @alert_prof.assign_to_objects(@vm.id, "Vm")
    end

    it "should return true when calling target_needs_realtime_capture?" do
      expect(MiqAlert.target_needs_realtime_capture?(@vm)).to be_truthy
    end
  end

  context "With a Host assigned to a v4-style realtime C&U alert" do
    before(:each) do
      allow_any_instance_of(MiqAlert).to receive_messages(:validate => true)
      @host     = FactoryGirl.create(:host)
      @alert    = FactoryGirl.create(:miq_alert, :enabled => true, :db => "Host", :responds_to_events => "xxx|host_perf_complete|zzz")
      @alert_prof = FactoryGirl.create(:miq_alert_set, :description => "Alert Profile for Alert Id: #{@alert.id}", :mode => @host.class.base_model.name)
      @alert_prof.add_member(@alert)
      # V4 code is actually the same here -- assign_to_objects -- but
      # this forces the namespace to use actual model class name
      # rather than base_class
      @alert_prof.assign_to_objects(@host.id, "Host")
    end

    it "should return true when calling target_needs_realtime_capture?" do
      expect(MiqAlert.target_needs_realtime_capture?(@host)).to be_truthy
    end
  end

  context ".evaluate_hourly_timer" do
    before do
      allow_any_instance_of(MiqAlert).to receive_messages(:validate => true)
      @miq_server = EvmSpecHelper.local_miq_server
      @ems        = FactoryGirl.create(:ems_vmware, :zone => @miq_server.zone)
      @ems_other  = FactoryGirl.create(:ems_vmware, :zone => FactoryGirl.create(:zone, :name => 'other'))
      @alert      = FactoryGirl.create(:miq_alert, :enabled => true, :responds_to_events => "_hourly_timer_")
      @alert_prof = FactoryGirl.create(:miq_alert_set, :description => "Alert Profile for Alert Id: #{@alert.id}")
      @alert_prof.add_member(@alert)
    end

    it "evaluates for ext_management_system" do
      @alert.update_attributes(:db => "ExtManagementSystem")
      @alert_prof.mode = @ems.class.base_model.name
      @alert_prof.assign_to_objects(@ems.id, "ExtManagementSystem")

      expect(MiqAlert).to receive(:evaluate_alerts).with(@ems, "_hourly_timer_")
      MiqAlert.evaluate_hourly_timer
    end

    it "evaluates for vm" do
      vm_in_zone = FactoryGirl.create(:vm_vmware, :ext_management_system => @ems)
      vm_in_other = FactoryGirl.create(:vm_vmware, :ext_management_system => @ems_other)
      vm_no_ems = FactoryGirl.create(:vm_vmware)
      @alert.update_attributes(:db => "Vm")
      @alert_prof.mode = vm_in_zone.class.base_model.name
      @alert_prof.assign_to_objects(vm_in_zone.id, "Vm")

      expect(MiqAlert).to receive(:evaluate_alerts).once.with(vm_in_zone, "_hourly_timer_")
      expect(MiqAlert).to receive(:evaluate_alerts).once.with(vm_no_ems, "_hourly_timer_")
      expect(MiqAlert).not_to receive(:evaluate_alerts).with(vm_in_other, "_hourly_timer_")
      MiqAlert.evaluate_hourly_timer
    end

    it "evaluates for storage" do
      storage_in_zone = FactoryGirl.create(:storage_vmware)
      FactoryGirl.create(:host, :ext_management_system => @ems, :storages => [storage_in_zone])

      storage_in_another = FactoryGirl.create(:storage_vmware)
      FactoryGirl.create(:host, :ext_management_system => @ems_other, :storages => [storage_in_another])

      storage_in_host_no_ems = FactoryGirl.create(:storage_vmware)
      FactoryGirl.create(:host, :storages => [storage_in_host_no_ems])

      storage_no_ems = FactoryGirl.create(:storage_vmware)

      @alert.update_attributes(:db => "Storage")
      @alert_prof.mode = storage_in_zone.class.base_model.name
      @alert_prof.assign_to_objects(storage_in_zone.id, "Storage")

      expect(MiqAlert).to receive(:evaluate_alerts).once.with(storage_in_zone, "_hourly_timer_")
      expect(MiqAlert).to receive(:evaluate_alerts).once.with(storage_in_host_no_ems, "_hourly_timer_")
      expect(MiqAlert).to receive(:evaluate_alerts).once.with(storage_no_ems, "_hourly_timer_")
      expect(MiqAlert).not_to receive(:evaluate_alerts).with(storage_in_another, "_hourly_timer_")
      MiqAlert.evaluate_hourly_timer
    end
  end
end
