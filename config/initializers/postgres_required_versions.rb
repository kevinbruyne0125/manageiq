ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend Module.new {
  def initialize(*args)
    super
    check_version if respond_to?(:check_version)
  end

  def check_version
    msg = "The version of PostgreSQL being connected to is incompatible with #{Vmdb::Appliance.PRODUCT_NAME} (13 required)"

    if postgresql_version < 100000
      raise msg
    end

    if postgresql_version < 130000 || postgresql_version >= 140000
      raise msg if Rails.env.production? && !ENV["UNSAFE_PG_VERSION"]
      $stderr.puts msg
    end
  end
}
