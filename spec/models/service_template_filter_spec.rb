require "spec_helper"
include ServiceTemplateHelper

describe "Service Filter" do
  before do
    @allowed_service_templates = []
    user_helper
    build_small_environment
    build_model
    @request = build_service_template_request("top", @user)
    service_template_stubs
    request_stubs
  end

  def build_model
    model = {"top"        => {:type    => 'composite', :children => ['middle']},
             "middle"     => {:type    => 'composite', :children => ['vm_service']},
             "vm_service" => {:type    => 'atomic',
                              :request => {:target_name => "fred", :src_vm_id => @src_vm.id,
                                           :number_of_vms => 1, :requester => @user}
                             }
            }
    build_service_template_tree(model)
  end

  context "#include_service" do
    it "all service templates" do
      @allowed_service_templates = %w(top middle vm_service)
      @request.create_request_tasks
      @request.miq_request_tasks.count.should eql(5)
    end

    it "filter out the atomic service" do
      @allowed_service_templates = %w(top middle)
      @request.create_request_tasks
      @request.miq_request_tasks.count.should eql(2)
    end

    it "filter out all services" do
      @allowed_service_templates = []
      @request.create_request_tasks
      @request.miq_request_tasks.count.should eql(1)
    end

    it "filter out middle service" do
      @allowed_service_templates = %w(top)
      @request.create_request_tasks
      @request.miq_request_tasks.count.should eql(1)
    end
  end

  context "#automate_result_include_service_template?" do
    let(:test_class) do
      Class.new do
        include ServiceTemplate::Filter
        def initialize(workspace)
          @workspace = workspace
        end
      end
    end

    let(:workspace) { instance_double("MiqAeEngine::MiqAeWorkspace", :root => options) }

    context "allow" do
      let(:options) { {'include_service' => true} }
      it "check true value" do
        MiqAeEngine.stub(:resolve_automation_object).and_return(workspace)
        expect(test_class.automate_result_include_service_template?('a', @user, 'b')).to be_true
      end
    end

    context "dont allow" do
      let(:options) { {'include_service' => false} }
      it "check false value" do
        MiqAeEngine.stub(:resolve_automation_object).and_return(workspace)
        expect(test_class.automate_result_include_service_template?('a', @user, 'b')).to be_false
      end
    end

    context "not present" do
      let(:options) { {} }
      it "check nil value" do
        MiqAeEngine.stub(:resolve_automation_object).and_return(workspace)
        expect(test_class.automate_result_include_service_template?('a', @user, 'b')).to be_true
      end
    end
  end
end
