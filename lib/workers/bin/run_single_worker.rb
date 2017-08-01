# Runs a single MiqWorker class in isolation
#
#
# The following rubocop rules don't apply to this script
#
# rubocop:disable Rails/Output, Rails/Exit

require "optparse"

options = {}
opt_parser = OptionParser.new do |opts|
  opts.banner = "usage: #{File.basename $PROGRAM_NAME, '.rb'} MIQ_WORKER_CLASS_NAME"

  opts.on("-l", "--[no-]list", "Toggle viewing available worker class names") do |val|
    options[:list] = val
  end

  opts.on("-b", "--[no-]heartbeat", "Toggle heartbeating with worker monitor (DRB)") do |val|
    options[:heartbeat] = val
  end

  opts.on("-d", "--[no-]dry-run", "Dry run (don't create/start worker)") do |val|
    options[:dry_run] = val
  end

  opts.on("-g=GUID", "--guid=GUID", "Find an existing worker record instead of creating") do |val|
    options[:guid] = val
  end

  opts.on("-h", "--help", "Displays this help") do
    puts opts
    exit
  end
end
opt_parser.parse!
worker_class = ARGV[0]

require File.expand_path("../miq_worker_types", __dir__)

if options[:list]
  puts ::MIQ_WORKER_TYPES.keys
  exit
end
opt_parser.abort(opt_parser.help) unless worker_class

unless ::MIQ_WORKER_TYPES.keys.include?(worker_class)
  puts "ERR:  `#{worker_class}` WORKER CLASS NOT FOUND!  Please run with `-l` to see possible worker class names."
  exit 1
end

# Skip heartbeating with single worker
ENV["DISABLE_MIQ_WORKER_HEARTBEAT"] ||= options[:heartbeat] ? nil : '1'
ENV["BUNDLER_GROUPS"] = MIQ_WORKER_TYPES[worker_class].join(',')

require File.expand_path("../../../config/environment", __dir__)

worker_class = worker_class.constantize
worker_class.before_fork
unless options[:dry_run]
  create_options = {}
  runner_options = {}

  if ENV["QUEUE"]
    create_options[:queue_name] = ENV["QUEUE"]
    runner_options[:ems_id] = worker_class.ems_id_from_queue_name(ENV["QUEUE"]) if worker_class.respond_to?(:ems_id_from_queue_name)
  end

  worker = if options[:guid]
             worker_class.find_by!(:guid => options[:guid])
           else
             worker_class.create_worker_record(create_options)
           end

  begin
    worker.class::Runner.start_worker(runner_options.merge(:guid => worker.guid))
  ensure
    worker.delete
  end
end
