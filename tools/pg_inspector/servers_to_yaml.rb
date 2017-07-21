require 'trollop'
require 'pg'
require 'pg_inspector/error'
require 'pg_inspector/pg_inspector_operation'
require 'pg_inspector/util'

module PgInspector
  class ServersYAML < PgInspectorOperation
    HELP_MSG_SHORT = "Dump ManageIQ server information to YAML file".freeze

    def parse_options(args)
      self.options = Trollop.options(args) do
        banner <<-BANNER

#{HELP_MSG_SHORT}

Use password in PGPASSWORD environment if no password file given.
The file will be named as <output>_MM-DD-YYYY_HH:MM:SS.yml. Time is local time.

Options:
BANNER
        opt(:pg_host, "PostgreSQL host name or address",
            :type => :string, :short => "s", :default => "127.0.0.1")
        opt(:port, "PostgreSQL server port",
            :short => "p", :default => 5432)
        opt(:user, "PostgreSQL user",
            :type => :string, :short => "u", :default => "postgres")
        opt(:database, "ManageIQ Database to output server information",
            :type => :string, :short => "d", :default => "vmdb_production")
        opt(:output, "Output file prefix",
            :type => :string, :short => "o", :default => "server")
        opt(:password_file, "File content to use as password",
            :type => :string, :short => "f")
      end
    end

    def run
      Util.dump_to_yml_file(
        table_from_db_conn(
          connect_pg_server, "miq_servers"
        ), "ManageIQ server information", make_output_file_name(options[:output])
      )
    end

    private

    def connect_pg_server
      conn_options = {
        :dbname => options[:database],
        :host   => options[:pg_host],
        :port   => options[:port]
      }
      if options[:user]
        conn_options[:user] = options[:user]
      end
      if options[:password_file]
        conn_options[:password] = Util.readfile(options[:password_file]).strip
      elsif ENV["PGPASSWORD"]
        conn_options[:password] = ENV["PGPASSWORD"]
      end
      PG::Connection.open(conn_options)
    rescue PG::Error => e
      Util.error_exit(e)
    end

    def table_from_db_conn(conn, table_name)
      query = <<-SQL
SELECT *
FROM #{table_name};
SQL
      result = []
      res = conn.exec_params(query)
      res.each do |row|
        result << row
      end
      result
    rescue PG::Error => e
      Util.error_exit(e)
    end

    def make_output_file_name(base_name)
      timestamp = Time.new.getlocal.strftime("%m-%d-%Y_%H:%M:%S")
      "#{base_name}_#{timestamp}.yml"
    end
  end
end
