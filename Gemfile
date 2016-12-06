raise "Ruby versions less than 2.2.2 are unsupported!" if RUBY_VERSION < "2.2.2"
#
# VMDB specific gems
#

# when using this Gemfile inside a providers Gemfile, the dependency for the provider is already declared
unless dependencies.detect { |d| d.name == "manageiq-providers-amazon" }
  gem "manageiq-providers-amazon", :git => "https://github.com/ManageIQ/manageiq-providers-amazon", :branch => "euwe"
end

# Unmodified gems
gem "activerecord-session_store",     "~>1.0.0"
gem "actioncable",                    "~>5.0.0"
gem "acts_as_list",                   "~>0.7.2"
gem "acts_as_tree",                   "~>2.1.0" # acts_as_tree needs to be required so that it loads before ancestry
gem "ancestry",                       "~>2.2.1",       :require => false
gem "ansible_tower_client",           "~>0.4.1",       :require => false
gem "aws-sdk",                        "~>2.2.19",      :require => false
gem "color",                          "~>1.8"
gem "config",                         "~>1.3.0",       :require => false
gem "dalli",                          "~>2.7.4",       :require => false
gem "draper",                         "~>3.0.0.pre1"
gem "default_value_for",              "~>3.0.2"
gem "elif",                           "=0.1.0",        :require => false
gem "fast_gettext",                   "~>1.2.0"
gem "fog-google",                     "~>0.3.0",       :require => false
gem "fog-vcloud-director",            "~>0.1.6",       :require => false
gem "gettext_i18n_rails",             "~>1.7.2"
gem "gettext_i18n_rails_js",          "~>1.1.0"
gem "google-api-client",              "~>0.8.6",       :require => false
gem "hamlit",                         "~>2.7.0"
gem "hashie",                         ">=3.4.6",       :require => false
gem "high_voltage",                   "~>2.4.0"
gem "htauth",                         "2.0.0",         :require => false
gem "inifile",                        "~>3.0",         :require => false
gem "jbuilder",                       "~>2.5.0" # For the REST API
gem "manageiq-api-client",            "~>0.1.0",       :require => false
gem "mime-types",                     "~>2.6.1",       :require => "mime/types/columnar"
gem "nakayoshi_fork",                 "~>0.0.3"  # provides a more CoW friendly fork (GC a few times before fork)
gem "net-ldap",                       "~>0.14.0",      :require => false
gem "net-ping",                       "~>1.7.4",       :require => false
gem "net-ssh",                        "=3.2.0",        :require => false
gem "net_app_manageability",          ">=0.1.0",       :require => false
gem "novnc-rails",                    "~>0.2"
gem "omniauth",                       "~>1.3.1",       :require => false
gem "omniauth-google-oauth2",         "~>0.2.6"
gem "open4",                          "~>1.3.0",       :require => false
gem "outfielding-jqplot-rails",       "= 1.0.8"
gem "ovirt-engine-sdk",               "~>4.0.5",       :require => false # Required by the oVirt provider
gem "ovirt_metrics",                  "~>1.4.0",       :require => false
gem "paperclip",                      "~>4.3.0"
gem "puma",                           "~>3.3.0"
gem "query_relation",                 "~>0.1.0",       :require => false
gem "rails",                          "~>5.0.0.1"
gem "rails-controller-testing",                        :require => false
gem "rails-i18n",                     "~>5.x"
gem "recursive-open-struct",          "~>1.0.0"
gem "responders",                     "~>2.0"
gem "ruby-dbus" # For external auth
gem "ruby-progressbar",               "~>1.7.0",       :require => false
gem "ruby_parser",                    "~>3.8",         :require => false
gem "rufus-scheduler",                "~>3.1.3",       :require => false
gem "rugged",                         "=0.25.0b10",    :require => false
gem "secure_headers",                 "~>3.0.0"
gem "simple-rss",                     "~>1.3.1",       :require => false
gem "snmp",                           "~>1.2.0",       :require => false
gem "sshkey",                         "~>1.8.0",       :require => false
gem "thin",                           "~>1.7.0",       :require => false
gem "uglifier",                       "~>3.0.0"
gem "websocket-driver",               "~>0.6.3"

# Modified gems (forked on Github)
gem "foreman_api_client",             ">=0.1.0",   :require => false, :git => "https://github.com/ManageIQ/foreman_api_client.git", :branch => "master"
gem "ruport",                         "=1.7.0",                       :git => "https://github.com/ManageIQ/ruport.git", :tag => "v1.7.0-3"

# In 1.9.3: Time.parse uses british version dd/mm/yyyy instead of american version mm/dd/yyyy
# american_date fixes this to be compatible with 1.8.7 until all callers can be converted to the 1.9.3 format prior to parsing.
# See miq_expression_spec Date/Time Support examples.
# https://github.com/jeremyevans/ruby-american_date
gem "american_date"

group :automate do
  gem "savon",                        "~>2.2.0",   :require => false  # Automate uses this for simple SOAP Integration
end

group :ui_dependencies do # Added to Bundler.require in config/application.rb
  # Unmodified gems
  gem "angular-ui-bootstrap-rails",   "~>0.13.0"
  gem "jquery-hotkeys-rails"
  gem "lodash-rails",                 "~>3.10.0"
  gem "patternfly-sass",              "~>3.15.0"
  gem "sass-rails"
  gem "coffee-rails"

  # Modified gems (forked on Github)
  gem "jquery-rjs",                   "=0.1.1",                       :git => "https://github.com/ManageIQ/jquery-rjs.git", :tag => "v0.1.1-1"
end

### Start of gems excluded from the appliances.
# The gems listed below do not need to be packaged until we find it necessary or useful.
# Only add gems here that we do not need on an appliance.
#
unless ENV["APPLIANCE"]
  group :development do
    gem "haml_lint",        "~>0.16.1", :require => false
    gem "rubocop",          "~>0.37.2", :require => false
    gem "scss_lint",        "~>0.48.0", :require => false
  end

  group :test do
    gem "brakeman",         "~>3.3",    :require => false
    gem "capybara",         "~>2.5.0",  :require => false
    gem "factory_girl",     "~>4.5.0",  :require => false
    gem "jasmine",                      :require => false
    gem "sqlite3",                      :require => false
  end

  group :development, :test do
    gem "good_migrations"
    gem "parallel_tests"
    gem "rspec-rails",      "~>3.5.0"
  end
end

#
# Custom Gemfile modifications
#

# Load developer specific Gemfile
#   Developers can create a file called Gemfile.dev.rb containing any gems for
#   their local development.  This can be any gem under evaluation that other
#   developers may not need or may not easily install, such as rails-dev-boost,
#   any git based gem, and compiled gems like rbtrace or memprof.
dev_gemfile = File.expand_path("Gemfile.dev.rb", __dir__)
eval_gemfile(dev_gemfile) if File.exist?(dev_gemfile)

# Load other additional Gemfiles
eval_gemfile(File.expand_path("gems/pending/Gemfile", __dir__))
Dir.glob("bundler.d/*.rb").each { |f| eval_gemfile(File.expand_path(f, __dir__)) }
