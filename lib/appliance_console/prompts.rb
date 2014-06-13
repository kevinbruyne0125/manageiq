module ApplianceConsole
  module Prompts
    CLEAR_CODE    = `clear`
    IP_REGEXP     = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
    DATE_REGEXP   = /^(2[0-9]{3})-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])/
    TIME_REGEXP   = /^(0?[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])/
    INT_REGEXP    = /^[0-9]+$/
    HOSTNAME_REGEXP = /^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/

    SAMPLE_URLS = {
      'nfs' => 'nfs://host.mydomain.com/exported/my_exported_folder/db.backup',
      'smb' => 'smb://host.mydomain.com/my_share/daily_backup/db.backup',
    }

    def sample_url(scheme)
      SAMPLE_URLS[scheme]
    end

    def ask_for_uri(prompt, expected_scheme)
      require 'uri'
      just_ask(prompt, nil, nil, 'a valid URI') do |q|
        q.validate = lambda do |a|
          # Convert all backslashes in the URI to forward slashes and strip whitespace
          a.gsub!('\\', '/')
          a.strip!
          scheme, _, host, _, _, path, _, _, _ = URI.split(URI.encode(a))
          # validate it has a hostname/ip and a share
          scheme == expected_scheme && (host.to_s =~ HOSTNAME_REGEXP || host.to_s =~ IP_REGEXP) && path.to_s.length > 0
        end
      end
    end

    def press_any_key
      say("\nPress any key to continue.")
      begin
        system("stty raw -echo")
        STDIN.getc
      ensure
        system("stty -raw echo")
      end
    end

    def clear_screen
      print CLEAR_CODE
    end

    def are_you_sure?(clarifier = nil)
      clarifier = " you want to #{clarifier}" if clarifier && !clarifier.include?("want")
      agree("Are you sure#{clarifier}? (Y/N): ")
    end

    def ask_for_ip(prompt, default, validate = IP_REGEXP, error_text = "a valid IP Address.", &block)
      just_ask(prompt, default, validate, error_text, &block)
    end

    def ask_for_ip_or_none(prompt, default = nil)
      validation = ->(p) { p.empty? || p =~ /^'?NONE'?$/i || p =~ IP_REGEXP }
      ask_for_ip(prompt, default, validation).gsub(/^'?NONE'?$/i, "")
    end

    def ask_for_ip_or_hostname(prompt, default = nil)
      validation = ->(h) { (h =~ HOSTNAME_REGEXP || h =~ IP_REGEXP) && h.length > 0 }
      ask_for_ip(prompt, default, validation, "a valid Hostname or IP Address.")
    end

    def ask_for_ip_or_hostname_or_none(prompt, default = nil)
      validation = ->(h) { h.empty? || h =~ /^'?NONE'?$/i || h =~ HOSTNAME_REGEXP || h =~ IP_REGEXP }
      ask_for_ip(prompt, default, validation, "a valid Hostname or IP Address.").gsub(/^'?NONE'?$/i, "")
    end

    def ask_for_many(prompt, collective = nil, default = nil, max_length = 255, max_count = 6)
      collective ||= "#{prompt}s"
      validate = ->(p) { (p.length < max_length) && (p.split(/[\s,;]+/).length <= max_count) }
      error_message = "up to #{max_count} #{prompt}s separated by a space and up to #{max_length} characters"
      just_ask(collective, default, validate, error_message).split(/[\s,;]+/).collect { |p| p.strip }
    end

    def ask_for_password(prompt, default = nil)
      pass = just_ask(prompt, default.present? ? "********" : nil) do |q|
        q.echo = '*'
        yield q if block_given?
      end
      pass == "********" ? (default || "") : pass
    end

    def ask_for_password_or_none(prompt, default = nil)
      ask_for_password(prompt, default).gsub(/^'?NONE'?$/i, "")
    end

    def ask_for_date(prompt)
      just_ask(prompt, nil, DATE_REGEXP)
    end

    def ask_for_time(prompt)
      just_ask(prompt, nil, TIME_REGEXP)
    end

    def ask_for_integer(prompt, range = nil)
      just_ask(prompt, nil, INT_REGEXP, "an integer", Integer) { |q| q.in = range if range }
    end

    def ask_for_disk(disk_name)
      require "linux_admin"
      disks = LinuxAdmin::Disk.local.select { |d| d.partitions.empty? }

      if disks.empty?
        say "No partition found for #{disk_name}. You probably want to add an unpartitioned disk and try again."
      else
        default_choice = disks.size == 1 ? "1" : nil
        disk = ask_with_menu(
          disk_name,
          disks.collect { |d| [("#{d.path}: #{d.size.to_i / 1.megabyte} MB"), d] },
          default_choice
        ) do |q|
          q.choice("Don't partition the disk") { nil }
        end
      end

      if disk.nil?
        say ""
        raise MiqSignalError unless are_you_sure?(" you don't want to partion the #{disk_name}")
      end
      disk
    end

    def ask_with_menu(prompt, options, default = nil, clear_screen_after = true)
      say("#{prompt}\n\n")
      selection = nil
      choose do |menu|
        menu.default      = default if default
        menu.index        = :number
        menu.index_suffix = ") "
        menu.prompt       = "\nChoose the #{prompt.downcase}:#{" |#{default}|" if default} "
        options.each { |o, v| menu.choice(o) { |c| selection = v || c } }
        yield menu if block_given?
      end
      clear_screen if clear_screen_after
      selection
    end

    def just_ask(prompt, default = nil, validate = nil, error_text = nil, klass = nil)
      ask("Enter the #{prompt}: ", klass) do |q|
        q.default = default if default
        q.validate = validate if validate
        q.responses[:not_valid] = error_text ? "Please provide #{error_text}" : "Please provide in the specified format"
        yield q if block_given?
      end
    end
  end
end
