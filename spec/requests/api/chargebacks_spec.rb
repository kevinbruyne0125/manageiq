require "spec_helper"

RSpec.describe "chargebacks API" do
  include Rack::Test::Methods

  def app
    Vmdb::Application
  end

  before { init_api_spec_env }

  it "can fetch the list of all chargeback rates" do
    chargeback_rate = FactoryGirl.create(:chargeback_rate)

    api_basic_authorize
    run_get chargebacks_url

    expect_result_resources_to_include_hrefs(
      "resources", [chargebacks_url(chargeback_rate.id)]
    )
    expect_result_to_match_hash(@result, "count" => 1)
    expect_request_success
  end

  it "can show an individual chargeback rate" do
    chargeback_rate = FactoryGirl.create(:chargeback_rate)

    api_basic_authorize
    run_get chargebacks_url(chargeback_rate.id)

    expect_result_to_match_hash(
      @result,
      "description" => chargeback_rate.description,
      "guid"        => chargeback_rate.guid,
      "id"          => chargeback_rate.id,
      "href"        => chargebacks_url(chargeback_rate.id)
    )
    expect_request_success
  end

  it "can fetch chargeback rate details" do
    chargeback_rate_detail = FactoryGirl.create(:chargeback_rate_detail)
    chargeback_rate = FactoryGirl.create(:chargeback_rate,
                                         :chargeback_rate_details => [chargeback_rate_detail])

    api_basic_authorize
    run_get "#{chargebacks_url(chargeback_rate.id)}/rates"

    expect_query_result(:rates, 1, 1)
    expect_result_resources_to_include_hrefs(
      "resources",
      ["#{chargebacks_url(chargeback_rate.id)}/rates/#{chargeback_rate_detail.to_param}"]
    )
    expect_request_success
  end

  it "can fetch an individual chargeback rate detail" do
    chargeback_rate_detail = FactoryGirl.create(:chargeback_rate_detail, :rate => 5)
    chargeback_rate = FactoryGirl.create(:chargeback_rate,
                                         :chargeback_rate_details => [chargeback_rate_detail])

    api_basic_authorize
    run_get "#{chargebacks_url(chargeback_rate.id)}/rates/#{chargeback_rate_detail.to_param}"

    expect_result_to_match_hash(
      @result,
      "chargeback_rate_id" => chargeback_rate.id,
      "href"               => "#{chargebacks_url(chargeback_rate.id)}/rates/#{chargeback_rate_detail.to_param}",
      "id"                 => chargeback_rate_detail.id,
      "rate"               => "5"
    )
    expect_request_success
  end

  it "can create a new chargeback rate detail" do
    api_basic_authorize
    run_post rates_url, :rate => 0, :enabled => true

    actual = @result["results"].first
    expect(actual["rate"]).to eq("0")
    expect(actual["enabled"]).to be true
    expect_request_success
  end

  it "can edit a chargeback rate detail through POST" do
    chargeback_rate_detail = FactoryGirl.create(:chargeback_rate_detail, :rate => 0)

    api_basic_authorize
    run_post rates_url(chargeback_rate_detail.id), gen_request(:edit, :rate => 0.02)

    expect(@result["rate"]).to eq("0.02")
    expect_request_success
    expect(chargeback_rate_detail.reload.rate).to eq("0.02")
  end

  it "can edit a chargeback rate detail through PATCH" do
    chargeback_rate_detail = FactoryGirl.create(:chargeback_rate_detail, :rate => 0)

    api_basic_authorize
    run_patch rates_url(chargeback_rate_detail.id), [gen_request(:edit, :rate => 0.02)]

    # expect(@result["rate"]).to eq("0.02")
    expect_request_success
    expect(chargeback_rate_detail.reload.rate).to eq("0.02")
  end

  it "can delete a chargeback rate detail" do
    chargeback_rate_detail = FactoryGirl.create(:chargeback_rate_detail)

    api_basic_authorize

    expect {
      run_delete rates_url(chargeback_rate_detail.id)
    }.to change(ChargebackRateDetail, :count).by(-1)
    expect(last_response.status).to eq(204)
  end

  it "can delete a chargeback rate detail through POST" do
    chargeback_rate_detail = FactoryGirl.create(:chargeback_rate_detail)

    api_basic_authorize

    expect {
      run_post rates_url(chargeback_rate_detail.id), :action => "delete"
    }.to change(ChargebackRateDetail, :count).by(-1)
    expect_request_success
  end
end
