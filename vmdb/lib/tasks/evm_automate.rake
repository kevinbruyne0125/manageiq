module EvmAutomate
  $:.push File.expand_path(File.join(Rails.root, %w{.. lib util xml}))

  def self.log(level, msg)
    $log.send(level, msg)
  end

  def self.reset_tables
    MiqAeDatastore.reset
  end

  def self.simulate(domain, namespace, class_name, instance_name)
    automate_attrs = {}
    uri = MiqAeEngine.create_automation_object(instance_name,
                                               automate_attrs,
                                               :fqclass => "#{domain}/#{namespace}/#{class_name}")
    MiqAeEngine.resolve_automation_object(uri)
  end

  def self.write_method_data(class_fqpath, method_name, content)
    FileUtils.mkpath(class_fqpath) unless File.directory?(class_fqpath)
    File.write(File.join(class_fqpath, "#{method_name.underscore}.rb"), content)
  end

  def self.list_class(ns)
    if ns.nil?
      MiqAeClass.all.sort_by(&:fqname).each { |c| puts "#{c.fqname}," }
    else
      class_list = MiqAeNamespace.find_by_fqname(ns).ae_classes.collect(&:fqname).join(", ")
      puts class_list
    end
  end

  def self.extract_methods(method_folder)
    MiqAeMethod.all.sort_by(&:fqname).each do |m|
      next unless m.location == 'inline'
      write_method_data(File.join(method_folder, m.ae_class.fqname), m['name'], m['data'])
    end
  end
end

namespace :evm do
  namespace :automate do

    desc 'Backup all automate domains to a zip file or backup folder.'
    task :backup => :environment do
      puts "Datastore backup starting"
      zip_file       = ENV['BACKUP_ZIP_FILE']
      begin
        MiqAeDatastore.backup('zip_file'  => zip_file,
                              'overwrite' => (ENV['OVERWRITE'].to_s.downcase == 'true'))
      rescue => err
        STDERR.puts err.message
        exit(1)
      end
    end

    desc 'Reset the ManageIQ domain to the default values'
    task :reset => :environment do
      puts "Reset the ManageIQ automation model"
      miq_model_dir = File.expand_path(File.join(Rails.root, "db/fixtures/datastore"))
      unless Dir.exist?(miq_model_dir)
        raise "The ManageIQ automation directory does not exist file: #{miq_model_dir}"
      end
      puts "Resetting the ManageIQ domain from : #{miq_model_dir}"
      MiqAeDatastore.reset_manageiq_domain(miq_model_dir)
      puts "The automate ManageIQ model has been reset."
    end

    desc 'Usage information regarding available tasks'
    task :usage => :environment do
      puts "The following automate tasks are available"
      puts " Import          - Usage: rake evm:automate:import PREVIEW=true DOMAIN=domain_name " \
                                "IMPORT_AS=new_domain_name IMPORT_DIR=./model_export|ZIP_FILE=filename "
      puts " Export          - Usage: rake evm:automate:export DOMAIN=domain_name "  \
                               "EXPORT_AS=new_domain_name NAMESPACE=sample CLASS=methods EXPORT_DIR=./model_export|ZIP_FILE=filename"
      puts " Backup          - Usage: rake evm:automate:backup BACKUP_ZIP_FILE=filename OVERWRITE=false"
      puts " Restore         - Usage: rake evm:automate:restore BACKUP_ZIP_FILE=filename"
      puts " Clear           - Usage: rake evm:automate:clear"
      puts " Reset           - Usage: rake evm:automate:reset"
      puts " Simulate        - Usage: rake evm:automate:simulate DOMAIN=domain_name NAMESPACE=sample CLASS=Methods INSTANCE=Inspectme"
      puts " Extract Methods - Usage: rake evm:automate:extract_methods FOLDER=automate_methods"
      puts " List Class      - Usage: rake evm:automate:list_class NAMESPACE=sample"
    end

    desc 'Deletes ALL automate model information for ALL domains.'
    task :clear => :environment do
      puts "Clearing the automation model"
      EvmAutomate.reset_tables
      puts "The automate model has been cleared."
    end

    desc 'Lists automate classes'
    task :list_class => :environment do
      namespace      = ENV["NAMESPACE"]
      puts "Listing automate classes#{" in #{namespace}" if namespace}"
      EvmAutomate.list_class(namespace)
    end

    desc 'Export automate model information to a folder or zip file. ENV options DOMAIN,NAMESPACE,CLASS,EXPORT_DIR|ZIP_FILE'
    task :export => :environment do
      begin
        domain         = ENV['DOMAIN']
        raise "Must specify domain for export:" if domain.nil?
        zip_file       = ENV['ZIP_FILE']
        export_dir     = ENV['EXPORT_DIR']
        if zip_file.nil? && export_dir.nil?
          zip_file = "./#{domain}.zip"
          puts "No export location specified. Exporting domain: #{domain} to: #{zip_file}"
        end
        export_options = {'export_dir' => export_dir,
                          'zip_file'   => zip_file,
                          'namespace'  => ENV['NAMESPACE'],
                          'class'      => ENV['CLASS'],
                          'overwrite'  => ENV['OVERWRITE'].to_s.downcase == 'true'}
        export_options['export_as'] = ENV['EXPORT_AS'] if ENV['EXPORT_AS'].present?
        MiqAeExport.new(domain, export_options).export
      rescue => err
        STDERR.puts err.backtrace
        STDERR.puts err.message
        exit(1)
      end
    end

    desc 'Import automate model information from an export folder or zip file. '
    task :import => :environment do
      begin
        raise "Must specify domain for export:" if ENV['DOMAIN'].blank?
        if ENV['IMPORT_DIR'].blank? && ENV['ZIP_FILE'].blank?
          raise 'Must specify either a directory with exported automate model or a zip file'
        end
        preview        = ENV['PREVIEW'] ||= 'true'
        raise 'Preview must be true or false' unless %w{true false}.include?(preview)
        mode           = ENV['MODE'] ||= 'add'
        import_as      = ENV['IMPORT_AS']
        import_options = {'preview'   => (preview.to_s.downcase == 'true'),
                          'mode'      => mode.to_s.downcase,
                          'namespace' => ENV['NAMESPACE'],
                          'class'     => ENV['CLASS'],
                          'import_as' => import_as}
        if ENV['ZIP_FILE'].nil?
          puts "Importing automate domain: #{ENV['DOMAIN']} from directory #{ENV['IMPORT_DIR']}"
          import_options['import_dir'] = ENV['IMPORT_DIR'] unless ENV['IMPORT_DIR'].nil?
        else
          puts "Importing automate domain: #{ENV['DOMAIN']} from file #{ENV['ZIP_FILE']}"
          import_options['zip_file']   = ENV['ZIP_FILE']   unless ENV['ZIP_FILE'].nil?
        end
        MiqAeImport.new(ENV['DOMAIN'], import_options).import
      rescue => err
        STDERR.puts err.backtrace
        STDERR.puts err.message
        exit(1)
      end
    end

    desc 'Extract automate methods'
    task :extract_methods => :environment do
      method_folder  = ENV["FOLDER"] ||= './automate_methods'
      puts "Extracting automate methods from database to folder: #{method_folder} ..."
      EvmAutomate.extract_methods(method_folder)
      puts "The automate methods have been extracted."
    end

    desc 'Method simulation'
    task :simulate => :environment do
      begin
        puts "Automate simulation starting"
        domain         = ENV["DOMAIN"]
        namespace      = ENV["NAMESPACE"]
        class_name     = ENV["CLASS"]
        instance_name  = ENV["INSTANCE"]
        err_msg = ""
        err_msg << "Must specify automate model domain\n"    if domain.nil?
        err_msg << "Must specify automate model namespace\n" if namespace.nil?
        err_msg << "Must specify automate model class\n"     if class_name.nil?
        err_msg << "Must specify automate model instance\n"  if instance_name.nil?
        unless err_msg.empty?
          err_msg << "Usage DOMAIN=customer NAMESPACE=sample CLASS=Methods INSTANCE=Inspectme\n "
          raise err_msg
        end
        EvmAutomate.simulate(domain, namespace, class_name, instance_name)
        puts "Automate simulation ending"
      rescue => err
        STDERR.puts err.message
        exit(1)
      end
    end

    desc 'Restore automate domains from a backup zip file or folder.'
    task :restore => :environment do
      begin
        raise 'Must specify a backup zip file' if ENV['BACKUP_ZIP_FILE'].blank?
        puts "Importing automate domains from file #{ENV['BACKUP_ZIP_FILE']}"

        MiqAeDatastore.reset
        MiqAeImport.new("*",
          'preview'  => false,
          'mode'     => 'add',
          'zip_file' => ENV['BACKUP_ZIP_FILE']
        ).import
      rescue => err
        STDERR.puts err.message
        exit(1)
      end
    end

    desc 'Convert the legacy automation model to new format  ENV options FILE,DOMAIN,EXPORT_DIR|ZIP_FILE'
    task :convert => :environment do
      puts "Convert automation model from the legacy xml file"
      domain_name    = ENV["DOMAIN"]
      raise "Must specify the DOMAIN name to convert as" if domain_name.nil?
      export_options = {}
      zip_file    = ENV['ZIP_FILE']
      export_dir  = ENV['EXPORT_DIR']
      overwrite   =  (ENV['OVERWRITE'] ||= 'false').downcase.==('true')

      export_options['zip_file'] = zip_file if zip_file
      export_options['export_dir'] = export_dir if export_dir
      export_options['overwrite'] = overwrite

      raise "Must specify the ZIP_FILE or EXPORT_DIR to store converted model" if zip_file.nil? && export_dir.nil?

      model_filename = ENV["FILE"]
      raise "Must specify legacy automation backup file xml to " + \
        "convert to the new automate model:  - Usage FILE='xml_filename'" if model_filename.nil?
      raise "Automation file to use for conversion does not " + \
        "exist: #{model_filename}"  unless File.exist?(model_filename)
      puts "Converting the automation model from the xml file: #{model_filename}"
      MiqAeDatastore.convert(model_filename, domain_name, export_options)
      puts "The automate model has been converted from : #{model_filename}"
      puts "Converted model in directory: #{export_dir}" if export_dir
      puts "Converted model in zip file: #{zip_file}" if zip_file
    end
  end
end
