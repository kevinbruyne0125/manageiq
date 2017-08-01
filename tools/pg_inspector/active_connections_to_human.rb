require 'trollop'
require 'yaml'
require 'time'
require 'activerecord-id_regions'
require 'pg_inspector/error'
require 'pg_inspector/pg_inspector_operation'
require 'pg_inspector/util'

module PgInspector
  class ActiveConnectionsHumanYAML < PgInspectorOperation
    HELP_MSG_SHORT = "Dump active connections to human readable YAML file".freeze
    def parse_options(args)
      self.options = Trollop.options(args) do
        opt(:connections, "Active connections file",
            :type => :string, :short => "c", :default => "active_connections.yml")
        opt(:servers, "Servers information file",
            :type => :string, :short => "s", :default => "server.yml")
        opt(:output, "Output file",
            :type => :string, :short => "o", :default => "human.yml")
      end
    end

    def run
      Util.dump_to_yml_file(
        merge_activity_and_server_info(
          process_stat_activity_file(options[:connections]),
          process_miq_info_file(options[:servers])
        ), "Human readable active connections", options[:output]
      )
    end

    private

    def process_stat_activity_file(file_name)
      stat_activities = YAML.load_file(file_name)
      result = {
        "servers"         => [],
        "workers"         => [],
        "connections"     => [],
        "other_processes" => []
      }
      stat_activities.each do |activity|
        if server_activity?(activity)
          current_activity = process_miq_activity(activity)
          push_new_server(result, current_activity)
          push_connection(result, current_activity)
        elsif worker_activity?(activity)
          current_activity = process_miq_activity(activity)
          push_new_worker(result, current_activity)
          push_connection(result, current_activity)
        else
          push_other_process(result, process_other_process(activity))
        end
      end
      result
    rescue => e
      Util.error_exit(e)
    end

    def push_new_server(result, activity)
      result["servers"].each do |server|
        if activity["server_id"] == server["server_id"]
          return result
        end
      end
      result["servers"] << filter_activity_for_server(activity)
      result
    end

    def filter_activity_for_server(activity)
      activity.select do |k, _v|
        %w(server_id
           name
           pid
           zone_id
           zone_name)
          .include?(k)
      end
    end

    def push_new_worker(result, activity)
      result["workers"].each do |worker|
        if activity["worker_id"] == worker["worker_id"]
          return result
        end
      end
      result["workers"] << filter_activity_for_worker(activity)
      result
    end

    def filter_activity_for_worker(activity)
      activity.select do |k, _v|
        %w(worker_id
           server_id
           class_name
           pid)
          .include?(k)
      end
    end

    def push_connection(result, activity)
      result["connections"] << filter_activity_for_connection(activity)
      result
    end

    def filter_activity_for_connection(activity)
      activity.select do |k, _v|
        %w(worker_id
           server_id
           datid
           datname
           spid
           usesysid
           usename
           client_port
           backend_start
           xact_start
           query_start
           state_change
           waiting
           state
           backend_xid
           backend_xmin
           query)
          .include?(k)
      end
    end

    def process_other_process(activity)
      activity["spid"] = activity["pid"].to_i
      activity.delete("pid")
      activity
    end

    def push_other_process(result, activity)
      result["other_processes"] << activity
      result
    end

    def server_activity?(activity)
      miq_activity?(activity) && activity["application_name"].split("|")[3] == "-"
    end

    def worker_activity?(activity)
      miq_activity?(activity) && activity["application_name"].split("|")[3] != "-"
    end

    def miq_activity?(activity)
      activity["application_name"].start_with?("MIQ")
    end

    def process_miq_activity(activity)
      activity["datid"] = activity["datid"].to_i
      activity["spid"] = activity["pid"].to_i
      activity.delete("pid")
      activity["usesysid"] = activity["usesysid"].to_i
      activity["client_port"] = activity["client_port"].to_i
      activity["backend_start"] = to_utc(activity["backend_start"])
      activity["xact_start"] = to_utc(activity["xact_start"])
      activity["query_start"] = to_utc(activity["query_start"])
      activity["state_change"] = to_utc(activity["state_change"])
      process_miq_activity_application_name(activity)
    end

    def to_utc(time_str)
      return Time.parse(time_str).utc.to_s if time_str
    end

    def process_miq_activity_application_name(activity)
      # Current :application_name format:
      # MIQ|<pid>|<server_id>|<worker_id>|<zone_id>|<class_name>|<zone_name>
      if activity["application_name"].end_with?("...")
        $stderr.puts("Warning: the application_name #{activity["application_name"]} is incomplete.")
      end
      _, pid, server_id, worker_id, zone_id, class_name, zone_name = activity["application_name"].split("|")
      activity["pid"] = pid.to_i
      activity["class_name"] = class_name
      activity["server_id"] = uncompress_id(server_id)
      activity["worker_id"] = uncompress_id(worker_id) if worker_id != "-"
      activity["zone_id"] = uncompress_id(zone_id)
      activity["zone_name"] = zone_name
      activity
    end

    def process_miq_info_file(file_name)
      servers = YAML.load_file(file_name)
      result = []
      servers.each { |server| result << process_miq_server(server) }
      result
    rescue => e
      Util.error_exit(e)
    end

    def process_miq_server(server)
      server["server_id"] = server["id"].to_i
      server.select do |k, _v|
        %w(server_id
           hostname
           ipaddress)
          .include?(k)
      end
    end

    def compress_id(id)
      Class.new.include(ActiveRecord::IdRegions).compress_id(id)
    end

    def uncompress_id(id)
      Class.new.include(ActiveRecord::IdRegions).uncompress_id(id)
    end

    def merge_activity_and_server_info(stat_activities, servers)
      server_activities = array_of_hash_to_hash(
        stat_activities["servers"], "server_id"
      )
      servers.each do |server|
        server_activities[server["server_id"]] =
          server_activities[server["server_id"]].merge(server)
      end
      stat_activities["servers"] = hash_val_array(server_activities)
      stat_activities
    end

    def array_of_hash_to_hash(array, key)
      result = {}
      array.each do |e|
        result[e[key]] = e
      end
      result
    end

    def hash_val_array(hash)
      result = []
      hash.each do |_k, v|
        result << v
      end
      result
    end
  end
end
