require 'drb'
module MiqAeEngine
  class DrbRemoteInvoker
    attr_accessor :num_methods

    def initialize(workspace)
      @workspace = workspace
      @num_methods = 0
    end

    def with_server(inputs, body)
      setup if num_methods == 0
      self.num_methods += 1

      svc = MiqAeMethodService::MiqAeService.new(@workspace)
      svc.inputs     = inputs
      svc.preamble   = method_preamble(drb_uri, svc.object_id)
      svc.body       = body

      yield [svc.preamble, svc.body, RUBY_METHOD_POSTSCRIPT]
    ensure
      svc.destroy # Reset inputs to empty to avoid storing object references
      self.num_methods -= 1
      teardown if num_methods == 0
    end

    private

    # invocation

    def drb_uri
      DRb.uri
    end

    def setup
      require 'drb/timeridconv'
      @@global_id_conv = DRb.install_id_conv(DRb::TimerIdConv.new(drb_cache_timeout))
      drb_front  = MiqAeMethodService::MiqAeServiceFront.new
      drb        = DRb.start_service("druby://127.0.0.1:0", drb_front)
    end

    def teardown
      DRb.stop_service
      # Set the ID conv to nil so that the cache can be GC'ed
      DRb.install_id_conv(nil)
      # This hack was done to prevent ruby from leaking the
      # TimerIdConv thread.
      # https://bugs.ruby-lang.org/issues/12342
      thread = @@global_id_conv
               .try(:instance_variable_get, '@holder')
               .try(:instance_variable_get, '@keeper')
      @@global_id_conv = nil
      return unless thread

      thread.kill
      Thread.pass while thread.alive?
    end

    def drb_cache_timeout
      1.hour
    end

    # code building

    def method_preamble(miq_uri, miq_id)
      "MIQ_URI = '#{miq_uri}'\nMIQ_ID = #{miq_id}\n" << RUBY_METHOD_PREAMBLE
    end

    RUBY_METHOD_PREAMBLE = <<-RUBY
class AutomateMethodException < StandardError
end

begin
  require 'date'
  require 'rubygems'
  $:.unshift("#{Gem.loaded_specs['activesupport'].full_gem_path}/lib")
  require 'active_support/all'
  require 'socket'
  Socket.do_not_reverse_lookup = true  # turn off reverse DNS resolution

  require 'drb'
  require 'yaml'

  Time.zone = 'UTC'

  MIQ_OK    = 0
  MIQ_WARN  = 4
  MIQ_ERROR = 8
  MIQ_STOP  = 8
  MIQ_ABORT = 16

  DRbObject.send(:undef_method, :inspect)
  DRbObject.send(:undef_method, :id) if DRbObject.respond_to?(:id)

  DRb.start_service
  $evmdrb = DRbObject.new_with_uri(MIQ_URI)
  raise AutomateMethodException,"Cannot create DRbObject for uri=\#{MIQ_URI}" if $evmdrb.nil?
  $evm = $evmdrb.find(MIQ_ID)
  raise AutomateMethodException,"Cannot find Service for id=\#{MIQ_ID} and uri=\#{MIQ_URI}" if $evm.nil?
  MIQ_ARGS = $evm.inputs
rescue Exception => err
  STDERR.puts('The following error occurred during inline method preamble evaluation:')
  STDERR.puts("  \#{err.class}: \#{err.message}")
  STDERR.puts("  \#{err.backtrace.join('\n')}") unless err.kind_of?(AutomateMethodException)
  raise
end

class Exception
  def backtrace_with_evm
    value = backtrace_without_evm
    value ? $evm.backtrace(value) : value
  end

  alias backtrace_without_evm backtrace
  alias backtrace backtrace_with_evm
end

begin
RUBY

    RUBY_METHOD_POSTSCRIPT = <<-RUBY
rescue Exception => err
  unless err.kind_of?(SystemExit)
    $evm.log('error', 'The following error occurred during method evaluation:')
    $evm.log('error', "  \#{err.class}: \#{err.message}")
    $evm.log('error', "  \#{err.backtrace[0..-2].join('\n')}")
  end
  raise
ensure
  $evm.disconnect_sql
end
RUBY
  end
end
