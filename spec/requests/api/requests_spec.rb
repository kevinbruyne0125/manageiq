RSpec.describe "Requests API" do
  let(:template) { FactoryGirl.create(:service_template, :name => "ServiceTemplate") }

  context "authorization" do
    it "is forbidden for a user without appropriate role" do
      api_basic_authorize

      run_get requests_url

      expect(response).to have_http_status(:forbidden)
    end

    it "does not list another user's requests" do
      other_user = FactoryGirl.create(:user)
      FactoryGirl.create(:service_template_provision_request,
                         :requester   => other_user,
                         :source_id   => template.id,
                         :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      run_get requests_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("name" => "requests", "count" => 1, "subcount" => 0)
    end

    it "does not show another user's request" do
      other_user = FactoryGirl.create(:user)
      service_request = FactoryGirl.create(:service_template_provision_request,
                                           :requester   => other_user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)

      run_get requests_url(service_request.id)

      expected = {
        "error" => a_hash_including(
          "message" => /Couldn't find MiqRequest/
        )
      }
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to include(expected)
    end

    it "a user can list their own requests" do
      _service_request = FactoryGirl.create(:service_template_provision_request,
                                            :requester   => @user,
                                            :source_id   => template.id,
                                            :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      run_get requests_url

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("name" => "requests", "count" => 1, "subcount" => 1)
    end

    it "a user can show their own request" do
      service_request = FactoryGirl.create(:service_template_provision_request,
                                           :requester   => @user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)

      run_get requests_url(service_request.id)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("id"   => service_request.id,
                                       "href" => a_string_matching(service_requests_url(service_request.id)))
    end

    it "lists all the service requests if you are admin" do
      allow_any_instance_of(User).to receive(:admin?).and_return(true)
      other_user = FactoryGirl.create(:user)
      service_request_1 = FactoryGirl.create(:service_template_provision_request,
                                             :requester   => other_user,
                                             :source_id   => template.id,
                                             :source_type => template.class.name)
      service_request_2 = FactoryGirl.create(:service_template_provision_request,
                                             :requester   => @user,
                                             :source_id   => template.id,
                                             :source_type => template.class.name)
      api_basic_authorize collection_action_identifier(:requests, :read, :get)

      run_get requests_url

      expected = {
        "count"     => 2,
        "subcount"  => 2,
        "resources" => a_collection_containing_exactly(
          {"href" => a_string_matching(requests_url(service_request_1.id))},
          {"href" => a_string_matching(requests_url(service_request_2.id))},
        )
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "an admin can see another user's request" do
      allow_any_instance_of(User).to receive(:admin?).and_return(true)
      other_user = FactoryGirl.create(:user)
      service_request = FactoryGirl.create(:service_template_provision_request,
                                           :requester   => other_user,
                                           :source_id   => template.id,
                                           :source_type => template.class.name)
      api_basic_authorize action_identifier(:requests, :read, :resource_actions, :get)

      run_get requests_url(service_request.id)

      expected = {
        "id"   => service_request.id,
        "href" => a_string_matching(service_requests_url(service_request.id))
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  context "request creation" do
    it "is forbidden for a user to create a request without appropriate role" do
      api_basic_authorize

      run_post(requests_url, gen_request(:create, :service_type => "ServiceReconfigureRequest"))

      expect(response).to have_http_status(:forbidden)
    end

    it "is forbidden for a user to create a request without a different request role" do
      api_basic_authorize collection_action_identifier(:requests, :create),
                          MiqRequest::REQUEST_TYPE_ROLE_IDENTIFIER[:VmReconfigureRequest]

      run_post(requests_url, gen_request(:create, :request_type => "ServiceReconfigureRequest"))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails if the request_type is missing" do
      api_basic_authorize collection_action_identifier(:requests, :create)

      run_post(requests_url, gen_request(:create, :src_id => 4))

      expect_bad_request(/Must specify a request_type/)
    end

    it "fails if the request_type is unknown" do
      api_basic_authorize collection_action_identifier(:requests, :create)

      run_post(requests_url, gen_request(:create, :request_type => "InvalidRequest"))

      expect_bad_request(/Invalid Request Type InvalidRequest specified/)
    end

    it "fails if the request is missing a src_id" do
      api_basic_authorize collection_action_identifier(:requests, :create),
                          MiqRequest::REQUEST_TYPE_ROLE_IDENTIFIER[:ServiceReconfigureRequest]

      run_post(requests_url, gen_request(:create, :request_type => "ServiceReconfigureRequest"))

      expect_bad_request(/Must specify a resource src_id or src_ids/)
    end

    it "fails if the requester is invalid" do
      api_basic_authorize collection_action_identifier(:requests, :create),
                          MiqRequest::REQUEST_TYPE_ROLE_IDENTIFIER[:ServiceReconfigureRequest]

      run_post(requests_url, gen_request(:create,
                                         :request_type => "ServiceReconfigureRequest",
                                         :src_id       => 4,
                                         :requester    => { "user_name" => "invalid_user"}))

      expect_bad_request(/Unknown requester user_name invalid_user specified/)
    end

    it "succeed" do
      api_basic_authorize collection_action_identifier(:requests, :create),
                          MiqRequest::REQUEST_TYPE_ROLE_IDENTIFIER[:ServiceReconfigureRequest]

      service = FactoryGirl.create(:service, :name => "service1")
      run_post(requests_url, gen_request(:create,
                                         :request_type => "ServiceReconfigureRequest",
                                         :auto_approve => false,
                                         :src_id       => service.id))

      expected = {
        "results" => [
          a_hash_including(
            "description"    => "Service Reconfigure for: #{service.name}",
            "approval_state" => "pending_approval",
            "type"           => "ServiceReconfigureRequest",
            "requester_name" => api_config(:user_name),
            "options"        => a_hash_including("src_id" => service.id)
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "succeed immediately with optional data and auto_approve set to true" do
      api_basic_authorize collection_action_identifier(:requests, :create),
                          MiqRequest::REQUEST_TYPE_ROLE_IDENTIFIER[:ServiceReconfigureRequest]

      approver = FactoryGirl.create(:user_miq_request_approver)
      service = FactoryGirl.create(:service, :name => "service1")
      run_post(requests_url, gen_request(:create,
                                         :request_type => "ServiceReconfigureRequest",
                                         :requester    => { "user_name" => approver.userid },
                                         :auto_approve => true,
                                         :other_attr   => "other value",
                                         :src_id       => service.id))

      expected = {
        "results" => [
          a_hash_including(
            "description"    => "Service Reconfigure for: #{service.name}",
            "approval_state" => "approved",
            "type"           => "ServiceReconfigureRequest",
            "requester_name" => approver.name,
            "options"        => a_hash_including("src_id" => service.id, "other_attr" => "other value")
          )
        ]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end
  end

  context "request update" do
    it "is forbidden for a user without appropriate role" do
      api_basic_authorize

      run_post(requests_url, gen_request(:edit))

      expect(response).to have_http_status(:forbidden)
    end

    it "fails with an invalid request id" do
      api_basic_authorize collection_action_identifier(:requests, :edit)

      run_post(requests_url(999_999), gen_request(:edit, :some_option => "some_value"))

      expected = {
        "error" => a_hash_including(
          "message" => /Couldn't find MiqRequest/
        )
      }
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to include(expected)
    end

    it "succeed" do
      api_basic_authorize collection_action_identifier(:requests, :edit)

      service = FactoryGirl.create(:service, :name => "service1")
      request = ServiceReconfigureRequest.create_request({ :src_id => service.id }, @user, false)

      run_post(requests_url(request.id), gen_request(:edit, :some_option => "some_value"))

      expected = {
        "id"      => request.id,
        "options" => a_hash_including("some_option" => "some_value")
      }

      expect_single_resource_query(expected)
      expect(response).to have_http_status(:ok)
    end
  end
end
