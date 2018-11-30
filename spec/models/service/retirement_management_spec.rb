describe "Service Retirement Management" do
  let(:user) { FactoryGirl.create(:user) }
  before(:each) do
    @server = EvmSpecHelper.local_miq_server
    @service = FactoryGirl.create(:service)
  end

  it "#retirement_check" do
    expect(MiqEvent).to receive(:raise_evm_event)
    @service.update_attributes(:retires_on => 90.days.ago, :retirement_warn => 60, :retirement_last_warn => nil)
    expect(@service.retirement_last_warn).to be_nil
    expect_any_instance_of(@service.class).to receive(:retire_now).once
    @service.retirement_check
    @service.reload
    expect(@service.retirement_last_warn).not_to be_nil
    expect(Time.now.utc - @service.retirement_last_warn).to be < 30
  end

  it "#start_retirement" do
    expect(@service.retirement_state).to be_nil
    @service.start_retirement
    @service.reload
    expect(@service.retirement_state).to eq("retiring")
  end

  it "#retire_now" do
    expect(@service.retirement_state).to be_nil
    expect(MiqEvent).to receive(:raise_evm_event).once
    @service.retire_now
    expect(@service.retirement_state).to eq('initializing')
  end

  it "#retire_now when called more than once" do
    expect(@service.retirement_state).to be_nil
    expect(MiqEvent).to receive(:raise_evm_event).once
    3.times { @service.retire_now }
    expect(@service.retirement_state).to eq('initializing')
  end

  it "#retire_now not called when already retiring" do
    @service.update_attributes(:retirement_state => 'retiring')
    expect(MiqEvent).to receive(:raise_evm_event).exactly(0).times
    @service.retire_now
  end

  it "#retire_now not called when already retired" do
    @service.update_attributes(:retirement_state => 'retired')
    expect(MiqEvent).to receive(:raise_evm_event).exactly(0).times
    @service.retire_now
  end

  it "#retire_now with userid" do
    expect(@service.retirement_state).to be_nil
    event_name = 'request_service_retire'
    event_hash = {:userid => user.userid, :service => @service, :type => "Service"}

    expect(MiqEvent).to receive(:raise_evm_event).with(@service, event_name, event_hash, :user_id => user.id).once

    @service.retire_now(user.userid)
  end

  it "#retire_now without userid" do
    expect(@service.retirement_state).to be_nil
    event_name = 'request_service_retire'
    event_hash = {:userid => nil, :service => @service, :type => "Service"}

    expect(MiqEvent).to receive(:raise_evm_event).with(@service, event_name, event_hash, {}).once

    @service.retire_now
  end

  it "#retire warn" do
    expect(AuditEvent).to receive(:success).once
    options = {}
    options[:warn] = 2.days.to_i
    @service.retire(options)
    @service.reload
    expect(@service.retirement_warn).to eq(options[:warn])
  end

  it "#retire date" do
    expect(AuditEvent).to receive(:success).once
    options = {}
    options[:date] = Time.zone.today
    @service.retire(options)
    @service.reload
    expect(@service.retires_on).to eq(options[:date])
  end

  context "bundled service retires all children" do
    let(:vm) { FactoryGirl.create(:vm_vmware) }
    let(:vm1) { FactoryGirl.create(:vm_vmware) }
    let(:service_c1) { FactoryGirl.create(:service, :service => @service) }
    let(:service_c2) { FactoryGirl.create(:service, :service => service_c1) }

    before do
      service_c1 << vm
      service_c2 << vm1
      @service.save
      service_c1.save
      service_c2.save
    end

    it "sets up bundled service" do
      @service.service_resources << FactoryGirl.create(:service_resource, :resource_type => "VmOrTemplate", :service_id => service_c1.id, :resource_id => vm.id)
      @service.service_resources << FactoryGirl.create(:service_resource, :resource_type => "VmOrTemplate", :service_id => service_c1.id, :resource_id => vm1.id)
      @service.service_resources << FactoryGirl.create(:service_resource, :resource_type => "Service", :service_id => service_c1.id, :resource_id => service_c1.id)
      expect(@service.service_resources.size).to eq(3)
      expect(@service.service_resources.sort.first.resource).to receive(:retire_now).once
      expect(@service.service_resources.sort.second.resource).to receive(:retire_now).once
      expect(@service.service_resources.sort.third.resource).not_to receive(:retire_now)
      @service.retire_service_resources
    end
  end

  describe "#retire_service_resources" do
    context "when service resource is not a service" do
      it "retires the service resource" do
        ems = FactoryGirl.create(:ems_vmware, :zone => @server.zone)
        @service << FactoryGirl.create(:vm_vmware, :ems_id => ems.id)
        expect(@service.service_resources.size).to eq(1)
        expect(@service.service_resources.first.resource).to receive(:retire_now)
        @service.retire_service_resources
      end
    end
    context "when service resource is a service" do
      it "doesn't retire the service resource" do
        service_c1 = FactoryGirl.create(:service)
        @service.service_resources << FactoryGirl.create(:service_resource, :service_id => service_c1.id, :resource => service_c1)
        expect(@service.service_resources.size).to eq(1)
        expect(@service.service_resources.first.resource).not_to receive(:retire_now)
        @service.retire_service_resources
      end
    end
    context "when service resources are both service and vm_or_template" do
      it "retires only the vm resource type service resource" do
        service_c1 = FactoryGirl.create(:service)
        vm = FactoryGirl.create(:vm)
        @service.service_resources << FactoryGirl.create(:service_resource, :service_id => service_c1.id, :resource => vm)
        @service.service_resources << FactoryGirl.create(:service_resource, :service_id => service_c1.id, :resource => service_c1)
        expect(@service.service_resources.size).to eq(2)
        expect(@service.service_resources.sort.first.resource).to receive(:retire_now)
        expect(@service.service_resources.sort.second.resource).not_to receive(:retire_now)
        @service.retire_service_resources
      end
    end
    it "#retire_service_resources should get service's retirement_requester" do
      ems = FactoryGirl.create(:ems_vmware, :zone => @server.zone)
      vm  = FactoryGirl.create(:vm_vmware, :ems_id => ems.id)
      userid = 'freddy'
      @service.update_attributes(:retirement_requester => userid)
      @service << vm
      expect(@service.service_resources.size).to eq(1)
      expect(@service.service_resources.first.resource).to receive(:retire_now).with(userid)
      @service.retire_service_resources
    end
    it "#retire_service_resources should get service's nil retirement_requester" do
      ems = FactoryGirl.create(:ems_vmware, :zone => @server.zone)
      vm  = FactoryGirl.create(:vm_vmware, :ems_id => ems.id)
      @service << vm
      expect(@service.service_resources.size).to eq(1)
      expect(@service.service_resources.first.resource).to receive(:retire_now).with(nil)
      @service.retire_service_resources
    end
  end

  it "#finish_retirement" do
    expect(@service.retirement_state).to be_nil
    @service.finish_retirement
    @service.reload
    expect(@service.retired).to be_truthy
    expect(@service.retires_on).to be_between(Time.zone.now - 1.hour, Time.zone.now + 1.second)
    expect(@service.retirement_state).to eq("retired")
  end

  it "#retiring - false" do
    expect(@service.retirement_state).to be_nil
    expect(@service.retiring?).to be_falsey
  end

  it "#retiring - true" do
    @service.update_attributes(:retirement_state => 'retiring')
    expect(@service.retiring?).to be_truthy
  end

  it "#error_retiring - false" do
    expect(@service.retirement_state).to be_nil
    expect(@service.error_retiring?).to be_falsey
  end

  it "#error_retiring - true" do
    @service.update_attributes(:retirement_state => 'error')
    expect(@service.error_retiring?).to be_truthy
  end

  it "#retires_on - today" do
    expect(@service.retirement_due?).to be_falsey
    @service.retires_on = Time.zone.today
    expect(@service.retirement_due?).to be_truthy
  end

  it "#retires_on - tomorrow" do
    expect(@service.retirement_due?).to be_falsey
    @service.retires_on = Time.zone.today + 1
    expect(@service.retirement_due?).to be_falsey
  end

  it "#retirement_due?" do
    expect(@service.retirement_due?).to be_falsey

    @service.update_attributes(:retires_on => Time.zone.today + 1.day)
    expect(@service.retirement_due?).to be_falsey

    @service.update_attributes(:retires_on => Time.zone.today)
    expect(@service.retirement_due?).to be_truthy

    @service.update_attributes(:retires_on => Time.zone.today - 1.day)
    expect(@service.retirement_due?).to be_truthy
  end

  it "#raise_retirement_event" do
    event_name = 'foo'
    event_hash = {:userid => nil, :service => @service, :type => "Service"}
    expect(MiqEvent).to receive(:raise_evm_event).with(@service, event_name, event_hash, {})
    @service.raise_retirement_event(event_name)
  end

  it "#raise_audit_event" do
    event_name = 'foo'
    message = 'bar'
    event_hash = {:target_class => "Service", :target_id => @service.id.to_s, :event => event_name, :message => message}
    expect(AuditEvent).to receive(:success).with(event_hash)
    @service.raise_audit_event(event_name, message)
  end
end
