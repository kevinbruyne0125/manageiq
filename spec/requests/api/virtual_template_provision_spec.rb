describe ApiController do
  let(:ems) { FactoryGirl.create(:ext_management_system) }
  let(:availability_zone) { FactoryGirl.create(:availability_zone_google)}
  let(:cloud_network) { FactoryGirl.create(:cloud_network) }
  let(:flavor) { FactoryGirl.create(:flavor_google) }
  let(:virtual_template) { FactoryGirl.create(:virtual_template_google, :ems_id => ems.id, :availability_zone_id => availability_zone.id, :cloud_network_id => cloud_network.id, :flavor_id => flavor.id) }
  let(:dialog)     { FactoryGirl.create(:miq_dialog_provision) }
  let(:request) do
    {
      'vm_name' => 'VirtualTemplate',
      'requester' => {
        'owner_first_name' => 'First',
        'owner_last_name' => 'Last',
        'owner_email' => 'email@email.com',
        'request_notes' => 'A Test Provision'
      }
    }
  end

  describe 'Virtual Template Provision Request' do
    let(:expected_attributes) { %w(id options) }

    it 'provisions a virtual template' do
      api_basic_authorize subcollection_action_identifier(:virtual_templates, :provision, :create)

      request_url = "#{virtual_templates_url(virtual_template.id)}/provision"

      dialog
      run_post(request_url, request)
      expect(response).to have_http_status(:ok)
      expect_result_resources_to_include_keys('results', expected_attributes)

      task_id = response_hash['results'].first['id']
      expect(MiqProvisionRequest.exists?(task_id)).to be_truthy
    end

    it 'rejects requests without appropriate role' do
      api_basic_authorize

      request_url = "#{virtual_templates_url(virtual_template.id)}/provision"

      run_post(request_url, request)
      expect(response).to have_http_status(:forbidden)
    end
  end
end