namespace :test do
  namespace :security do
    task :setup # NOOP - Stub for consistent CI testing

    desc "Run Brakeman"
    task :brakeman do
      require "brakeman"

      # See all possible options here:
      #   http://www.rubydoc.info/gems/brakeman/Brakeman#run-class_method
      tracker = Brakeman.run(
        :app_path     => ".",
        :quiet        => false,
        :print_report => true
      )

      # Exit 1 on any warnings so CI can report the project as red.
      exit tracker.filtered_warnings.empty? ? 0 : 1
    end
  end

  desc "Run security tests"
  task :security => "security:brakeman"
end
