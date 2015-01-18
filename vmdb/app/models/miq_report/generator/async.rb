module MiqReport::Generator::Async
  extend ActiveSupport::Concern
  module ClassMethods
    def async_generate_tables(options = {})
      options[:userid] ||= "system"
      sync = VMDB::Config.new("vmdb").config[:product][:report_sync]

      task = MiqTask.create(:name => "Generate Reports: #{options[:reports].collect(&:name).inspect}")
      MiqQueue.put(
        :queue_name  => "generic",
        :role        => "reporting",
        :class_name  => self.to_s,
        :method_name => "_async_generate_tables",
        :args        => [task.id, options],
        :priority    => MiqQueue::HIGH_PRIORITY,
        :msg_timeout => self.default_queue_timeout.to_i_with_method
      ) unless sync # Only queued if sync reporting disabled (default)
      AuditEvent.success(:event => "generate_tables", :target_class => self.base_class.name, :userid => options[:userid], :message => "#{task.name}, successfully initiated")
      task.update_status("Queued", "Ok", "Task has been queued")
      self._async_generate_tables(task.id, options) if sync # Only runs if sync reporting enabled
      return task.id
    end

    def _async_generate_tables(taskid, options = {})
      task = MiqTask.find_by_id(taskid)
      raise MiqException::Error, "Unable to generate report if a task with id [#{taskid}] is not found!" unless task

      task.update_status("Active", "Ok", "Generating reports")
      reports = options.delete(:reports)
      reports.each_with_index do |rpt, index|
        rpt.generate_table(options)
        pct_complete = reports.length / (index + 1) * 100.0
        task.info("Generation of report [#{rpt.name}] complete", pct_complete)
      end

      task.task_results = reports
      task.save
      task.update_status("Finished", "Ok", "Generating reports complete")
    end

    def _async_generate_table(taskid, rpt, options = {})
      rpt._async_generate_table(taskid, options)
    end
  end

  def async_generate_table(options = {})
    options[:userid] ||= "system"
    sync = VMDB::Config.new("vmdb").config[:product][:report_sync]

    task = MiqTask.create(:name => "Generate Report: '#{self.name}'")
    unless sync # Only queued if sync reporting disabled (default)
      cb = {:class_name => task.class.name, :instance_id => task.id, :method_name => :queue_callback_on_exceptions, :args => ['Finished']}
      unless self.new_record?
        MiqQueue.put(
          :queue_name   => "generic",
          :role         => "reporting",
          :class_name   => self.class.to_s,
          :instance_id  => self.id,
          :method_name  => "_async_generate_table",
          :args         => [task.id, options],
          :priority     => MiqQueue::HIGH_PRIORITY,
          :miq_callback => cb,
          :msg_timeout  => self.queue_timeout
        )
      else
        MiqQueue.put(
          :queue_name   => "generic",
          :role         => "reporting",
          :class_name   => self.class.to_s,
          :method_name  => "_async_generate_table",
          :args         => [task.id, self, options],
          :priority     => MiqQueue::HIGH_PRIORITY,
          :miq_callback => cb,
          :msg_timeout  => self.queue_timeout
        )
      end
    end
    AuditEvent.success(:event => "generate_table", :target_class => self.class.base_class.name, :target_id => self.id, :userid => options[:userid], :message => "#{task.name}, successfully initiated")
    task.update_status("Queued", "Ok", "Task has been queued")
    self._async_generate_table(task.id, options) if sync # Only runs if sync reporting enabled
    return task.id
  end

  def _async_generate_table(taskid, options = {})
    # options = {
    #  :mode => "adhoc" (default)
    #  :session_id => 123
    # }
    task = MiqTask.find_by_id(taskid)
    task.update_status("Active", "Ok", "Generating report") if task
    audit = {:event => "generate_table", :target_class => self.class.base_class.name, :userid => options[:userid], :target_id => self.id}
    begin
      self.generate_table(options)
      options[:mode] ||= "adhoc"
      if options[:mode] == "adhoc" || options[:session_id]
        userid = "#{options[:userid]}|#{options[:session_id]}|#{options[:mode]}"
        options[:report_source] = "Generated by user"
        MiqReportResult.purge_for_user(options)
      else
        userid = options[:userid]
      end
      task.miq_report_result = self.build_create_results(options.merge(:userid => userid), taskid)
      task.save
      task.update_status("Finished", "Ok", "Generating report complete")
    rescue Exception => err
      $log.log_backtrace(err)
      task.error(err.message)
      AuditEvent.failure(audit.merge(:message => err.message))
      task.state_finished
      raise
    end
  end

end
