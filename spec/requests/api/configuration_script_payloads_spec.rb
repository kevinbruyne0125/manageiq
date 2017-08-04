RSpec.describe 'Configuration Script Payloads API' do
  describe 'GET /api/configuration_script_payloads' do
    it 'lists all the configuration script payloads with an appropriate role' do
      script_payload = FactoryGirl.create(:configuration_script_payload)
      api_basic_authorize collection_action_identifier(:configuration_script_payloads, :read, :get)

      run_get(configuration_script_payloads_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'configuration_script_payloads',
        'resources' => [
          hash_including('href' => a_string_matching(configuration_script_payloads_url(script_payload.compressed_id)))
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to configuration script payloads without an appropriate role' do
      api_basic_authorize

      run_get(configuration_script_payloads_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id' do
    it 'will show an ansible script_payload with an appropriate role' do
      script_payload = FactoryGirl.create(:configuration_script_payload)
      api_basic_authorize action_identifier(:configuration_script_payloads, :read, :resource_actions, :get)

      run_get(configuration_script_payloads_url(script_payload.id))

      expect(response.parsed_body)
        .to include('href' => a_string_matching(configuration_script_payloads_url(script_payload.compressed_id)))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to an ansible script_payload without an appropriate role' do
      script_payload = FactoryGirl.create(:configuration_script_payload)
      api_basic_authorize

      run_get(configuration_script_payloads_url(script_payload.id))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id/authentications' do
    it 'returns the configuration script sources authentications' do
      authentication = FactoryGirl.create(:authentication)
      playbook = FactoryGirl.create(:configuration_script_payload, :authentications => [authentication])
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :read, :get)

      run_get("#{configuration_script_payloads_url(playbook.id)}/authentications", :expand => 'resources')

      expected = {
        'resources' => [
          a_hash_including('id' => authentication.compressed_id)
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/configuration_script_payloads/:id/authentications' do
    let(:provider) { FactoryGirl.create(:provider_ansible_tower, :with_authentication) }
    let(:manager) { provider.managers.first }
    let(:playbook) { FactoryGirl.create(:configuration_script_payload, :manager => manager) }
    let(:params) do
      {
        :action      => 'create',
        :description => "Description",
        :name        => "A Credential",
        :related     => {},
        :type        => 'ManageIQ::Providers::AnsibleTower::AutomationManager::Credential'
      }
    end

    it 'requires that the type support create_in_provider_queue' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      run_post("#{configuration_script_payloads_url(playbook.id)}/authentications", :type => 'Authentication')

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'type not currently supported' }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'creates a new authentication with an appropriate role' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      run_post("#{configuration_script_payloads_url(playbook.id)}/authentications", params)

      expected = {
        'results' => [a_hash_including(
          'success' => true,
          'message' => 'Creating Authentication',
          'task_id' => a_kind_of(String)
        )]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create multiple authentications with an appropriate role' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :create)

      run_post("#{configuration_script_payloads_url(playbook.id)}/authentications", :resources => [params, params])

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'cannot create an authentication without appropriate role' do
      api_basic_authorize

      run_post("#{configuration_script_payloads_url(playbook.id)}/authentications", :resources => [params])

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_payloads/:id/authentications/:id' do
    it 'returns a specific authentication' do
      authentication = FactoryGirl.create(:authentication)
      playbook = FactoryGirl.create(:configuration_script_payload, :authentications => [authentication])
      api_basic_authorize subcollection_action_identifier(:configuration_script_payloads, :authentications, :read, :get)

      run_get("#{configuration_script_payloads_url(playbook.id)}/authentications/#{authentication.id}")

      expected = {
        'id' => authentication.compressed_id
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
