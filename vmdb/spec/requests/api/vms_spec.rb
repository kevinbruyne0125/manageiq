#
# REST API Request Tests - /api/vms
#
require 'spec_helper'

describe ApiController do

  include Rack::Test::Methods

  before(:each) do
    init_api_spec_env
  end

  def app
    Vmdb::Application
  end

  context "Vm accounts subcollection" do
    it "query VM accounts subcollection with no related accounts" do
      basic_authorize @cfme[:user], @cfme[:password]
      vm = FactoryGirl.create(:vm_vmware)
      @success = run_get "#{@cfme[:vms_url]}/#{vm.id}/accounts"
      expect(@code).to eq(200)
      expect(@result).to have_key("name")
      expect(@result["name"]).to eq("accounts")
      expect(@result["resources"]).to be_empty
    end

    it "query VM accounts subcollection with two related accounts" do
      basic_authorize @cfme[:user], @cfme[:password]
      vm = FactoryGirl.create(:vm_vmware)
      acct1 = FactoryGirl.create(:account, :vm_or_template_id => vm.id, :name => "John")
      acct2 = FactoryGirl.create(:account, :vm_or_template_id => vm.id, :name => "Jane")
      vm_accounts_url = "#{@cfme[:vms_url]}/#{vm.id}/accounts"
      @success = run_get vm_accounts_url
      expect(@success).to be_true
      expect(@code).to eq(200)
      expect(@result).to have_key("name")
      expect(@result["name"]).to eq("accounts")
      expect(@result["subcount"]).to eq(2)
      expect(@result["resources"].size).to eq(2)
      expect(resources_include_suffix?(@result["resources"], "href", "#{vm_accounts_url}/#{acct1.id}")).to be_true
      expect(resources_include_suffix?(@result["resources"], "href", "#{vm_accounts_url}/#{acct2.id}")).to be_true
    end

    it "query VM accounts subcollection with a valid Account Id" do
      basic_authorize @cfme[:user], @cfme[:password]
      vm = FactoryGirl.create(:vm_vmware)
      acct1 = FactoryGirl.create(:account, :vm_or_template_id => vm.id, :name => "John")
      @success = run_get "#{@cfme[:vms_url]}/#{vm.id}/accounts/#{acct1.id}"
      expect(@success).to be_true
      expect(@code).to eq(200)
      expect(@result).to have_key("name")
      expect(@result["name"]).to eq("John")
    end

    it "query VM accounts subcollection with an invalid Account Id" do
      basic_authorize @cfme[:user], @cfme[:password]
      vm = FactoryGirl.create(:vm_vmware)
      FactoryGirl.create(:account, :vm_or_template_id => vm.id, :name => "John")
      @success = run_get "#{@cfme[:vms_url]}/#{vm.id}/accounts/9999"
      expect(@success).to be_false
      expect(@code).to eq(404)
    end

    it "query VM accounts subcollection with two related accounts using expand directive" do
      basic_authorize @cfme[:user], @cfme[:password]
      vm = FactoryGirl.create(:vm_vmware)
      vm_url = "#{@cfme[:vms_url]}/#{vm.id}"
      vm_accounts_url = "#{vm_url}/accounts"
      acct1 = FactoryGirl.create(:account, :vm_or_template_id => vm.id, :name => "John")
      acct2 = FactoryGirl.create(:account, :vm_or_template_id => vm.id, :name => "Jane")
      @success = run_get "#{vm_url}?expand=accounts"
      expect(@success).to be_true
      expect(@code).to eq(200)
      expect(@result).to have_key("accounts")
      expect(@result["accounts"].size).to eq(2)
      expect(resources_include_suffix?(@result["accounts"], "id", "#{vm_accounts_url}/#{acct1.id}")).to be_true
      expect(resources_include_suffix?(@result["accounts"], "id", "#{vm_accounts_url}/#{acct2.id}")).to be_true
    end
  end
end
