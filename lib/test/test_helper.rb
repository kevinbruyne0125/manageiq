require_relative "../bundler_setup"
require 'minitest/unit'

# Push the lib directory onto the load path
$:.push(File.expand_path(File.join(File.dirname(__FILE__), '..')))
