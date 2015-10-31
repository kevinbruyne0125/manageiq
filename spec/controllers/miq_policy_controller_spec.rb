require "spec_helper"

describe MiqPolicyController do
  before(:each) do
    set_user_privileges
  end

  describe "#import" do
    include_context "valid session"

    let(:params) { {:import_file_upload_id => 123, :commit => commit} }
    let(:miq_policy_import_service) { auto_loaded_instance_double("MiqPolicyImportService") }

    before do
      MiqPolicyImportService.stub(:new).and_return(miq_policy_import_service)
    end

    shared_examples_for "MiqPolicyController#import" do
      it "assigns the import file upload id" do
        post :import, params
        assigns(:import_file_upload_id).should == "123"
      end
    end

    context "when the commit parameter is import" do
      let(:commit) { "import" }

      before do
        miq_policy_import_service.stub(:import_policy)
      end

      it_behaves_like "MiqPolicyController#import"

      it "imports a policy" do
        miq_policy_import_service.should_receive(:import_policy).with("123")
        post :import, params
      end
    end

    context "when the commit parameter is cancel" do
      let(:commit) { "cancel" }

      before do
        miq_policy_import_service.stub(:cancel_import)
      end

      it_behaves_like "MiqPolicyController#import"

      it "cancels the import" do
        miq_policy_import_service.should_receive(:cancel_import).with("123")
        post :import, params
      end
    end
  end

  describe "#upload" do
    include_context "valid session"

    shared_examples_for "MiqPolicyController#upload that cannot locate an import file" do
      it "redirects with a cannot locate import file error message" do
        post :upload, params
        response.should redirect_to(
          :action      => "export",
          :dbtype      => "dbtype",
          :flash_msg   => "Use the Browse button to locate an Import file",
          :flash_error => true
        )
      end
    end

    let(:params) { {:dbtype => "dbtype", :upload => upload} }

    context "when there is an upload parameter" do
      let(:upload) { {:file => file_contents} }

      context "when there is a file upload parameter" do
        context "when the file upload parameter responds to read" do
          let(:file_contents) do
            fixture_file_upload(Rails.root.join("spec/fixtures/files/import_policies.yml"), "text/yml")
          end

          let(:miq_policy_import_service) { auto_loaded_instance_double("MiqPolicyImportService") }

          before do
            MiqPolicyImportService.stub(:new).and_return(miq_policy_import_service)
            file_contents.stub(:read).and_return("file")
          end

          context "when there is not an error while importing" do
            let(:import_file_upload) { active_record_instance_double("ImportFileUpload", :id => 123) }

            before do
              miq_policy_import_service.stub(:store_for_import).and_return(import_file_upload)
            end

            it "sets the sandbox hide variable to true" do
              post :upload, params
              assigns(:sb)[:hide].should be_true
            end

            it "imports a policy" do
              miq_policy_import_service.should_receive(:store_for_import).with(file_contents)
              post :upload, params
            end

            it "redirects to import with the import_file_upload_id" do
              post :upload, params
              response.should redirect_to(:action => "import", :dbtype => "dbtype", :import_file_upload_id => 123)
            end
          end

          context "when there is an error while importing" do
            before do
              miq_policy_import_service.stub(:store_for_import)
                .with(file_contents).and_raise(StandardError.new("message"))
            end

            it "redirects to export with an error message" do
              post :upload, params
              response.should redirect_to(
                :action      => "export",
                :dbtype      => "dbtype",
                :flash_msg   => "Error during 'Policy Import': message",
                :flash_error => true
              )
            end
          end
        end

        context "when the file upload parameter does not respond to read" do
          let(:file_contents) { "does not respond to read" }

          it_behaves_like "MiqPolicyController#upload that cannot locate an import file"
        end
      end

      context "when there is not a file upload parameter" do
        let(:file_contents) { nil }

        it_behaves_like "MiqPolicyController#upload that cannot locate an import file"
      end
    end

    context "when there is not an upload parameter" do
      let(:upload) { nil }

      it_behaves_like "MiqPolicyController#upload that cannot locate an import file"
    end
  end

  describe '#explorer' do
    context 'when profile param present, but non-existent' do
      it 'renders explorer with flash message' do
        post :explorer, :profile => 42
        response.should render_template('explorer')
        flash_messages = controller.instance_variable_get(:@flash_array)
        flash_messages.find { |m| m[:message] == 'Policy Profile no longer exists' }.should_not be_nil
      end
    end

    context 'when profile param not present' do
      it 'renders explorer w/o flash message' do
        post :explorer
        response.should render_template('explorer')
        flash_messages = controller.instance_variable_get(:@flash_array)
        flash_messages.should be_nil
      end
    end

    context 'when profile param is valid' do
      it 'renders explorer w/o flash and assigns to x_node' do
        profile = FactoryGirl.create(:miq_policy_set)
        controller.stub(:get_node_info).and_return(true)
        post :explorer, :profile => profile.id
        response.should render_template('explorer')
        flash_messages = controller.instance_variable_get(:@flash_array)
        flash_messages.should be_nil
        controller.x_node.should == "pp_#{profile.id}"
      end
    end
  end

  describe '#tree_select' do
    [
      # [tree_sym, node, partial_name]
      [:policy_profile_tree, 'root', 'miq_policy/_profile_list'],
      [:policy_tree, 'root', 'miq_policy/_policy_folders'],
      [:event_tree, 'root', 'miq_policy/_event_list'],
      [:condition_tree, 'root', 'miq_policy/_condition_folders'],
      [:action_tree, 'root', 'miq_policy/_action_list'],
      [:alert_profile_tree, 'root', 'miq_policy/_alert_profile_folders'],
      [:alert_tree, 'root', 'miq_policy/_alert_list'],
    ].each do |tree_sym, node, partial_name|
      it "renders #{partial_name} when #{tree_sym} tree #{node} node is selected" do
        session[:sandboxes] = {"miq_policy" => {:active_tree => tree_sym}}
        session[:settings] ||= {}

        post :tree_select, :id => node, :format => :js
        response.should render_template(partial_name)
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#replace_right_cell' do
    it 'should replace policy_tree_div when replace_trees contains :policy' do
      controller.stub(:params).and_return(:action => 'whatever')
      controller.instance_eval { @sb = {:active_tree => :policy_tree} }
      controller.stub(:render).and_return(nil)
      presenter = ExplorerPresenter.new(:active_tree => :policy_tree)

      controller.send(:replace_right_cell, 'root', [:policy], presenter)
      expect(presenter[:replace_partials]).to have_key(:policy_tree_div)
    end

    it 'should not hide center toolbar while doing searches' do
      controller.stub(:params).and_return(:action => 'x_search_by_name')
      controller.instance_eval { @sb = {:active_tree => :action_tree} }
      controller.instance_eval { @edit = {:new => {:expression => {"???" => "???", :token => 1}}} }
      controller.stub(:render).and_return(nil)
      presenter = ExplorerPresenter.new(:active_tree => :action_tree)

      controller.send(:replace_right_cell, 'root', [:action], presenter)
      presenter[:set_visible_elements][:toolbar].should be_true
    end
  end

  describe 'x_button' do
    describe 'corresponding methods are called for allowed actions' do
      MiqPolicyController::POLICY_X_BUTTON_ALLOWED_ACTIONS.each_pair do |action_name, method|
        it "calls the appropriate method: '#{method}' for action '#{action_name}'" do
          controller.should_receive(method)
          get :x_button, :pressed => action_name
        end
      end
    end

    it 'exception is raised for unknown action' do
      get :x_button, :pressed => 'random_dude', :format => :html
      expect { response }.to render_template('layouts/exception')
    end
  end
end
