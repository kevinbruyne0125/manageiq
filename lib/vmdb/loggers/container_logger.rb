module Vmdb::Loggers
  class ContainerLogger < VMDBLogger
    def initialize(logdev = STDOUT, *args)
      super
      self.level = DEBUG
      self.formatter = Formatter.new
    end

    def level=(_new_level)
      super(DEBUG) # We want everything written to the ContainerLogger written to STDOUT
    end

    def filename
      "STDOUT"
    end

    class Formatter < VMDBLogger::Formatter
      SEVERITY_MAP = {
        "DEBUG"   => "debug",
        "INFO"    => "info",
        "WARN"    => "warning",
        "ERROR"   => "err",
        "FATAL"   => "crit",
        "UNKNOWN" => "unknown"
        # Others that don't match up: alert emerg notice trace
      }.freeze

      def call(severity, time, progname, msg)
        # From https://github.com/ViaQ/elasticsearch-templates/releases Downloads asciidoc
        {
          :@timestamp => format_datetime(time),
          :hostname   => hostname,
          :level      => translate_error(severity),
          :message    => prefix_task_id(msg2str(msg)),
          :pid        => $PROCESS_ID,
          :tid        => Thread.current.object_id,
          :service    => progname,
          # :tags => "tags string",
        }.to_json << "\n"
      end

      private

      def hostname
        @hostname ||= ENV["HOSTNAME"]
      end

      def translate_error(level)
        SEVERITY_MAP[level] || "unknown"
      end
    end
  end
end
