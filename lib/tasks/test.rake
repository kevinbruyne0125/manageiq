require_relative './evm_test_helper'

if defined?(RSpec)
namespace :test do
  task :initialize do
    ENV['RAILS_ENV'] ||= "test"
    Rails.env = ENV['RAILS_ENV'] if defined?(Rails)
    ENV['VERBOSE']   ||= "false"
  end

  task :setup_db => :initialize do
    puts "** Preparing database"
    Rake::Task['evm:db:reset'].invoke
  end
end

task :default => 'test:vmdb'
end # ifdef
