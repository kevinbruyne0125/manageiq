require "spec_helper"
require_migration

describe MigrateProviderAttributesToEndpoints do
  let(:provider_stub) { migration_stub(:Provider) }
  let(:endpoint_stub) { migration_stub(:Endpoint) }

  migration_context :up do
    it 'migrates Provider attributes to Endpoints' do
      provider_stub.create!(
        :verify_ssl => OpenSSL::SSL::VERIFY_NONE
      )

      migrate

      expect(endpoint_stub.count).to eq(1)
      expect(endpoint_stub.first).to have_attributes(
        :verify_ssl => OpenSSL::SSL::VERIFY_NONE
      )
    end

    it 'handles nil port value properly' do
      provider_stub.create!(
        :verify_ssl => nil
      )

      migrate

      expect(endpoint_stub.first).to have_attributes(
        :verify_ssl => nil
      )
    end
  end

  migration_context :down do
    it 'migrates Endpoints to Provider attributes' do
      provider = provider_stub.create!
      endpoint_stub.create!(
        :verify_ssl => OpenSSL::SSL::VERIFY_NONE
      )

      migrate

      expect(endpoint_stub.count).to eq(0)
      expect(provider.reload).to have_attributes(
        :verify_ssl => OpenSSL::SSL::VERIFY_NONE
      )
    end

    it 'handles nil port value properly' do
      provider = provider_stub.create!
      endpoint_stub.create!(
        :verify_ssl => nil
      )

      migrate

      expect(provider.reload).to have_attributes(
        :verify_ssl => nil
      )
    end
  end
end
