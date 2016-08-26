require 'securerandom'

#
# Supporting class for Managing Tokens, i.e. Authentication Tokens for REST API, etc.
#
class TokenManager
  RESTRICTED_OPTIONS = [:expires_on]
  DEFAULT_NS         = "default"

  @config       = {:token_ttl => 10.minutes}    # Token expiration managed in seconds

  def initialize(namespace, options)
    @namespace = namespace
    @options = options
  end

  def self.new(namespace = DEFAULT_NS, options = {})
    class_initialize(options)
    super(namespace, @config)
  end

  def gen_token(token_options = {})
    token = SecureRandom.hex(16)
    token_ttl_config = token_options.delete(:token_ttl_config)
    token_ttl = (token_ttl_config && @options[token_ttl_config]) ? @options[token_ttl_config] : @options[:token_ttl]
    token_data = {:token_ttl => token_ttl, :expires_on => Time.now.utc + token_ttl}

    token_store.write(token,
                      token_data.merge!(prune_token_options(token_options)),
                      :expires_in => @options[:token_ttl])
    token
  end

  def reset_token(token)
    token_data = token_store.read(token)
    return {} if token_data.nil?

    token_ttl = token_data[:token_ttl]
    token_store.write(token,
                      token_data.merge!(:expires_on => Time.now.utc + token_ttl),
                      :expires_in => token_ttl)
  end

  def token_get_info(token, what = nil)
    return {} unless token_valid?(token)

    what.nil? ? token_store.read(token) : token_store.read(token)[what]
  end

  def token_valid?(token)
    !token_store.read(token).nil?
  end

  def invalidate_token(token)
    token_store.delete(token)
  end

  private

  def token_store
    TokenStore.acquire(@namespace, @options[:token_ttl])
  end

  def self.class_initialize(options = {})
    @config.merge!(options)
  end
  private_class_method :class_initialize

  def prune_token_options(token_options = {})
    token_options.except(*RESTRICTED_OPTIONS)
  end
end
