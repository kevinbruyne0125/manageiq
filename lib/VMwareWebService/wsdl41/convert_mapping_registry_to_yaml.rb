class VimDummy
  EncodedRegistry = self

  def initialize(*args)
  end

  def self.const_missing(sym)
    return VimDummy
  end
end

XSD     = VimDummy
SOAP    = VimDummy
VimWs25 = VimDummy

module Registry
  @registry = Hash.new

  def self.register(args)
    argId = args[:schema_name] || args[:schema_type]
    if (sea = args[:schema_element])
      argHash  = Hash.new
      sea.each do |se|
        se[1] = se[1][0] if se[1].kind_of?(Array)
        se[1]['VimWs25::'] = '' if se[1] && se[1]['VimWs25::']
        if se[1] && se[1][/\[\]$/]
          se[1][/\[\]$/] = ''
          se << true
        else
          se << false
        end
        argHash[se[0]] = {}
        argHash[se[0]][:type] = se[1].to_sym if se[1]
        argHash[se[0]][:isArray] = true if se.last
      end
      @registry[argId] = argHash
    end
  end

  def self.set(*args)
  end

  def self.registry
    @registry
  end
end

EncodedRegistry = LiteralRegistry = Registry

$:.push(".")
require 'vimws25MappingRegistry'

require 'fileutils'
require 'yaml'
dir = File.expand_path("methods", File.dirname(__FILE__))
FileUtils.rm_rf(dir)
FileUtils.mkdir_p(dir)

Registry.registry.each do |name, args|
  File.open(File.join(dir, "#{name}.yml"), "w") do |f|
    f.puts("# THIS FILE WAS AUTOGENERATED. DO NOT MODIFY.")
    YAML.dump(args, f)
  end
end
