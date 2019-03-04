describe ServiceRetireTask do
  let(:user) { FactoryGirl.create(:user_with_group) }
  let(:vm) { FactoryGirl.create(:vm) }
  let(:service) { FactoryGirl.create(:service) }
  let(:miq_request) { FactoryGirl.create(:service_retire_request, :requester => user) }
  let(:service_retire_task) { FactoryGirl.create(:service_retire_task, :source => service, :miq_request => miq_request, :options => {:src_ids => [service.id] }) }
  let(:reason) { "Why Not?" }
  let(:approver) { FactoryGirl.create(:user_miq_request_approver) }
  let(:zone) { FactoryGirl.create(:zone, :name => "fred") }

  it "should initialize properly" do
    expect(service_retire_task).to have_attributes(:state => 'pending', :status => 'Ok')
  end

  describe "respond to update_and_notify_parent" do
    context "state queued" do
      it "should not call task_finished" do
        service_retire_task.update_and_notify_parent(:state => "queued", :status => "Ok", :message => "yabadabadoo")

        expect(service_retire_task.message).to eq("yabadabadoo")
      end
    end

    context "state finished" do
      it "should call task_finished" do
        service_retire_task.update_and_notify_parent(:state => "finished", :status => "Ok", :message => "yabadabadoo")

        expect(service_retire_task.status).to eq("Ok")
      end
    end
  end

  describe "#after_request_task_create" do
    context "sans resource" do
      it "doesn't create subtask" do
        service_retire_task.after_request_task_create

        expect(service_retire_task.description).to eq("Service Retire for: #{service.name} - ")
        expect(VmRetireTask.count).to eq(0)
        expect(ServiceRetireTask.count).to eq(1)
      end
    end

    context "with resource" do
      before do
        allow(MiqServer).to receive(:my_zone).and_return(Zone.seed.name)
        miq_request.approve(approver, reason)
      end

      it "creates service retire subtask" do
        service.add_resource!(FactoryBot.create(:service_orchestration))
        service_retire_task.after_request_task_create

        expect(service_retire_task.description).to eq("Service Retire for: #{service.name} - ")
        expect(ServiceRetireTask.count).to eq(2)
      end

      it "creates service retire subtask" do
        service.add_resource!(FactoryBot.create(:service))
        service_retire_task.after_request_task_create

        expect(service_retire_task.description).to eq("Service Retire for: #{service.name} - ")
        expect(ServiceRetireTask.count).to eq(2)
      end

      it "creates stack retire subtask" do
        service.add_resource!(FactoryBot.create(:orchestration_stack))
        service_retire_task.after_request_task_create

        expect(service_retire_task.description).to eq("Service Retire for: #{service.name} - ")
        expect(OrchestrationStackRetireTask.count).to eq(1)
        expect(ServiceRetireTask.count).to eq(1)
      end

      it "doesn't create subtask for miq_provision_request_template" do
        admin = FactoryBot.create(:user_admin)
        vm_template = FactoryBot.create(:vm_openstack, :ext_management_system => FactoryBot.create(:ext_management_system))
        service.add_resource!(FactoryBot.create(:miq_provision_request_template, :requester => admin, :src_vm_id => vm_template.id))
        service_retire_task.after_request_task_create

        expect(service_retire_task.description).to eq("Service Retire for: #{service.name} - ")
        expect(MiqRetireTask.count).to eq(1)
        expect(ServiceRetireTask.count).to eq(1)
      end

      it "creates vm retire subtask" do
        service.add_resource!(FactoryBot.create(:vm_openstack))
        service_retire_task.after_request_task_create

        expect(service_retire_task.description).to eq("Service Retire for: #{service.name} - ")
        expect(VmRetireTask.count).to eq(1)
        expect(ServiceRetireTask.count).to eq(1)
      end
    end

    context "bundled service retires all children" do
      let(:service_c1) { FactoryBot.create(:service) }

      before do
        service.add_resource!(service_c1)
        service.add_resource!(FactoryBot.create(:service_template))
        @miq_request = FactoryBot.create(:service_retire_request, :requester => user)
        @miq_request.approve(approver, reason)
        @service_retire_task = FactoryBot.create(:service_retire_task, :source => service, :miq_request => @miq_request, :options => {:src_ids => [service.id] })
      end

      it "creates subtask for services but not templates" do
        @service_retire_task.after_request_task_create

        expect(ServiceRetireTask.count).to eq(2)
        expect(ServiceRetireRequest.count).to eq(1)
      end

      it "doesn't creates subtask for ServiceTemplates" do
        @service_retire_task.after_request_task_create

        expect(ServiceRetireTask.count).to eq(2)
      end
    end
  end

  describe "deliver_to_automate" do
    before do
      allow(MiqServer).to receive(:my_zone).and_return(Zone.seed.name)
      miq_request.approve(approver, reason)
    end

    it "updates the task state to pending" do
      expect(service_retire_task).to receive(:update_and_notify_parent).with(
        :state   => 'pending',
        :status  => 'Ok',
        :message => 'Automation Starting'
      )
      service_retire_task.deliver_to_automate
    end
  end
end
