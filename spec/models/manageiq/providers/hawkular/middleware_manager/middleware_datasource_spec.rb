describe ManageIQ::Providers::Hawkular::MiddlewareManager::MiddlewareDatasource do
  let(:ems_hawkular) do
    # allow(MiqServer).to receive(:my_zone).and_return("default")
    _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
    auth = AuthToken.new(:name => "test", :auth_key => "valid-token", :userid => "jdoe", :password => "password")
    FactoryGirl.create(:ems_hawkular,
                       :hostname        => 'localhost',
                       :port            => 8080,
                       :authentications => [auth],
                       :zone            => zone)
  end

  let(:eap) do
    FactoryGirl.create(:hawkular_middleware_server,
                       :id                    => 1,
                       :name                  => 'Local',
                       :feed                  => 'e6b8348f-e84a-4bbf-aa5d-327cd7960aa7',
                       :ems_ref               => '/t;28026b36-8fe4-4332-84c8-524e173a68bf'\
                                                 '/f;e6b8348f-e84a-4bbf-aa5d-327cd7960aa7/r;Local~~',
                       :nativeid              => 'Local~~',
                       :ext_management_system => ems_hawkular)
  end

  let(:ds) do
    FactoryGirl.create(:hawkular_middleware_datasource,
                       :name                  => 'KeycloakDS',
                       :ems_ref               => '/t;28026b36-8fe4-4332-84c8-524e173a68bf'\
                                                 '/f;e6b8348f-e84a-4bbf-aa5d-327cd7960aa7/r;Local~~'\
                                                 '/r;Local~%2Fsubsystem%3Ddatasources%2Fdata-source%3DKeycloakDS',
                       :ext_management_system => ems_hawkular,
                       :middleware_server     => eap,
                       :properties            => {
                         'Driver Name'    => 'foo',
                         'Connection URL' => 'bar',
                         'JNDI Name'      => 'foo-bar',
                         'Enabled'        => 'yes'
                       })
  end

  it "#collect_live_metrics for all metrics available" do
    start_time = Time.new(2016, 6, 1, 13, 0, 0, "+02:00")
    end_time = Time.new(2016, 6, 1, 23, 0, 0, "+02:00")
    interval = 3600
    VCR.use_cassette(described_class.name.underscore.to_s,
                     :allow_unused_http_interactions => true,
                     :decode_compressed_response     => true) do #, :record => :new_episodes) do
      metrics_available = ds.metrics_available
      metrics_data = ds.collect_live_metrics(metrics_available, start_time, end_time, interval)
      keys = metrics_data.keys
      expect(metrics_data[keys[0]].keys.size).to be > 3
    end
  end

  it "#collect_live_metrics for three metrics" do
    start_time = Time.new(2016, 6, 1, 13, 0, 0, "+02:00")
    end_time = Time.new(2016, 6, 1, 23, 0, 0, "+02:00")
    interval = 3600
    VCR.use_cassette(described_class.name.underscore.to_s,
                     :allow_unused_http_interactions => true,
                     :decode_compressed_response     => true) do #, :record => :new_episodes) do
      metrics_available = ds.metrics_available
      expect(metrics_available.size).to be > 3
      metrics_data = ds.collect_live_metrics(metrics_available[0, 3],
                                             start_time,
                                             end_time,
                                             interval)
      keys = metrics_data.keys
      # Assuming that for the test the first key has data for 3 metrics
      expect(metrics_data[keys[0]].keys.size).to eq(3)
    end
  end

  it "#first_and_last_capture" do
    VCR.use_cassette(described_class.name.underscore.to_s,
                     :allow_unused_http_interactions => true,
                     :decode_compressed_response     => true) do #, :record => :new_episodes) do
      capture = ds.first_and_last_capture
      expect(capture[0]).to be < capture[1]
    end
  end

  it "#supported_metrics" do
    expected_metrics = {
      "Datasource Pool Metrics~Available Count"       => "mw_ds_available_count",
      "Datasource Pool Metrics~In Use Count"          => "mw_ds_in_use_count",
      "Datasource Pool Metrics~Timed Out"             => "mw_ds_timed_out",
      "Datasource Pool Metrics~Average Get Time"      => "mw_ds_average_get_time",
      "Datasource Pool Metrics~Average Creation Time" => "mw_ds_average_creation_time"
    }.freeze
    supported_metrics = MiddlewareDatasource.supported_metrics
    expected_metrics.each { |k, v| expect(supported_metrics[k]).to eq(v) }
  end
end
