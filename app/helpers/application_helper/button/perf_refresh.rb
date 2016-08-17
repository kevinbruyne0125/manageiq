class ApplicationHelper::Button::PerfRefresh < ApplicationHelper::Button::Basic
  def calculate_properties
    self[:hidden] = false
  end

  def skip?
    !@perf_options[:typ] == "realtime"
  end
end
