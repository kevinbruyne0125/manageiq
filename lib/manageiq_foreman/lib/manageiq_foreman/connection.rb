module ManageiqForeman
  class Connection
    # some foreman servers don't have locations or organizations, just return nil
    ALLOW_404 = [:locations, :organizations]
    CLASSES = {
      :config_templates  => ForemanApi::Resources::ConfigTemplate,
      :home              => ForemanApi::Resources::Home,
      :hostgroups        => ForemanApi::Resources::Hostgroup,
      :hosts             => ForemanApi::Resources::Host,
      :media             => ForemanApi::Resources::Medium,
      :operating_systems => ForemanApi::Resources::OperatingSystem,
      :ptables           => ForemanApi::Resources::Ptable,
      :subnets           => ForemanApi::Resources::Subnet,
      :locations         => ForemanApi::Resources::Location,
      :organizations     => ForemanApi::Resources::Organization,
    }

    attr_accessor :connection_attrs

    def initialize(connection_attrs)
      @connection_attrs = connection_attrs
    end

    def verify?
      results = Array(fetch(:home).try(:results)).first
      results.respond_to?(:key?) && results.key?("links")
    end

    def all(resource, filter = {})
      page = 0
      all = []

      loop do
        page_params = {:page => (page += 1), :per_page => 50}.merge(filter)
        small = fetch(resource, :index, page_params)
        return if small.nil? # 404
        all += small.to_a
        break if small.empty? || all.size >= small.total
      end
      PagedResponse.new(all)
    end

    # ala n+1
    def all_with_details(resource, filter = {})
      load_details(all(resource, filter), resource)
    end

    def load_details(resources, resource)
      resources.map! { |os| fetch(resource, :show, "id" => os["id"]).first } if resources
    end

    # filter: "page" => 2, "per_page" => 50, "search" => "field=value", "value"
    def fetch(resource, action = :index, filter = {})
      action, filter = :index, action if action.kind_of?(Hash)
      PagedResponse.new(raw(resource).send(action, filter).first)
    rescue RestClient::ResourceNotFound
      raise unless ALLOW_404.include?(resource)
      nil
    end

    def host(manager_ref)
      ::ManageiqForeman::Host.new(self, manager_ref)
    end

    def inventory
      Inventory.new(self)
    end

    private

    def raw(resource)
      CLASSES[resource].new(connection_attrs)
    end
  end
end
