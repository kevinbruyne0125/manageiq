module Authenticator
  class Ldap < Base
    def self.proper_name
      'LDAP'
    end

    def lookup_by_identity(username)
      super ||
        find_or_create_by_ldap(username)
    end

    private

    def ldap
      @ldap ||= ldap_bind(config[:bind_dn], config[:bind_pwd])
    end

    def ldap_bind(username, password)
      ldap = MiqLdap.new(:auth => config)
      ldap if ldap.bind(username, password)
    end

    def find_or_create_by_ldap(username)
      username = ldap.fqusername(username)
      user = User.find_by_userid(username)
      return user unless user.nil?

      raise "Unable to auto-create user because LDAP bind credentials are not configured" unless authorize?

      create_user_from_ldap(username) do |lobj|
        groups = match_groups(groups_for(lobj))
        raise "Unable to auto-create user because unable to match user's group membership to an EVM role" if groups.empty?
        groups
      end
    end

    def autocreate_user(username)
      # when default group for ldap users is enabled, create the user
      return unless config[:default_group_for_users]
      default_group = MiqGroup.where(:description => config[:default_group_for_users]).first
      return unless default_group
      create_user_from_ldap(username) { [default_group] }
    end

    def create_user_from_ldap(username)
      lobj = ldap.get_user_object(username)
      raise "Unable to auto-create user because LDAP search returned no data for user: [#{username}]" if lobj.nil?

      groups = yield lobj

      user = User.new
      update_user_attributes(user, username, lobj)
      user.miq_groups = groups
      user.save!
      $log.info("MIQ(Authenticator#create_user_from_ldap): Created User: [#{user.userid}]")

      user
    end

    def normalize_username(username)
      ldap.normalize(ldap.fqusername(username))
    end

    def _authenticate(username, password, _request)
      password.present? &&
        ldap_bind(username, password)
    end

    def find_external_identity(username)
      log_prefix = "MIQ(Authenticator#find_external_identity)"
      # Ldap will be used for authentication and role assignment
      $log.info("#{log_prefix} Bind DN: [#{config[:bind_dn]}]")
      $log.info("#{log_prefix}  User FQDN: [#{username}]")
      lobj = ldap.get_user_object(username)
      $log.debug("#{log_prefix} User obj from LDAP: #{lobj.inspect}")

      lobj
    end

    def userid_for(lobj, username)
      ldap.normalize(ldap.get_attr(lobj, :userprincipalname) || username)
    end

    DEFAULT_GROUP_MEMBERSHIPS_MAX_DEPTH = 2

    def groups_for(obj)
      authentication = config.dup
      authentication[:group_memberships_max_depth] ||= DEFAULT_GROUP_MEMBERSHIPS_MAX_DEPTH

      if authentication.key?(:user_proxies)       && !authentication[:user_proxies].blank?  &&
         authentication.key?(:get_direct_groups)  && authentication[:get_direct_groups] == false
        $log.info("MIQ(Authenticator#groups_for) Skipping getting group memberships directly assigned to user bacause it has been disabled in the configuration")
        groups = []
      else
        groups = ldap.get_memberships(obj, authentication[:group_memberships_max_depth])
      end

      if authentication.key?(:user_proxies)
        if (sid = MiqLdap.get_attr(obj, :objectsid))
          authentication[:user_proxies].each do |auth|
            begin
              groups += user_proxy_membership(auth, MiqLdap.sid_to_s(sid))
            rescue Exception => err
              $log.warn("MIQ(Authenticator#groups_for) #{err.message} (from Authenticator#user_proxy_membership)")
            end
          end
        else
          $log.warn("MIQ(Authenticator#groups_for) User Object has no objectSID")
        end
      end

      groups.uniq
    end

    def update_user_attributes(user, username, lobj)
      user.userid     = ldap.normalize(ldap.get_attr(lobj, :userprincipalname) || ldap.get_attr(lobj, :dn))
      user.name       = ldap.get_attr(lobj, :displayname)
      user.first_name = ldap.get_attr(lobj, :givenname)
      user.last_name  = ldap.get_attr(lobj, :sn)
      email           = ldap.get_attr(lobj, :mail)
      user.email      = email unless email.blank?
    end

    REQUIRED_LDAP_USER_PROXY_KEYS = [:basedn, :bind_dn, :bind_pwd, :ldaphost, :ldapport, :mode]
    def user_proxy_membership(auth, sid)
      log_prefix = "MIQ(Authenticator#user_proxy_membership)"

      authentication    = config
      auth[:bind_dn]  ||= authentication[:bind_dn]
      auth[:bind_pwd] ||= authentication[:bind_pwd]
      auth[:ldapport] ||= authentication[:ldapport]
      auth[:mode]     ||= authentication[:mode]
      auth[:group_memberships_max_depth] ||= DEFAULT_GROUP_MEMBERSHIPS_MAX_DEPTH

      REQUIRED_LDAP_USER_PROXY_KEYS.each { |key| raise "Required key not specified: [#{key}]" unless auth.key?(key) }

      fsp_dn  = "cn=#{sid},CN=ForeignSecurityPrincipals,#{auth[:basedn]}"

      ldap_up = MiqLdap.new(:auth => {:ldaphost => auth[:ldaphost], :ldapport => auth[:ldapport], :mode => auth[:mode], :basedn => auth[:basedn]})

      $log.info("#{log_prefix} Bind DN: [#{auth[:bind_dn]}], Host: [#{auth[:ldaphost]}], Port: [#{auth[:ldapport]}], Mode: [#{auth[:mode]}]")
      raise "Cannot Bind" unless ldap_up.bind(auth[:bind_dn], auth[:bind_pwd]) # now bind with bind_dn so that we can do our searches.
      $log.info("#{log_prefix} User SID: [#{sid}], FSP DN: [#{fsp_dn}]")
      user_proxy_object = ldap_up.search(:base => fsp_dn, :scope => :base).first
      raise "Unable to find user proxy object in LDAP" if user_proxy_object.nil?
      $log.debug("#{log_prefix} UserProxy obj from LDAP: #{user_proxy_object.inspect}")
      ldap_up.get_memberships(user_proxy_object, auth[:group_memberships_max_depth])
    end
  end
end
