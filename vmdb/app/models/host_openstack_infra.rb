class HostOpenstackInfra < Host
  belongs_to :availability_zone

  # TODO(lsmola) for some reason UI can't handle joined table cause there is hardcoded somewhere that it selects
  # DISTINCT id, with joined tables, id needs to be prefixed with table name. When this is figured out, replace
  # cloud tenant with rails relations
  # in /vmdb/app/models/miq_report/search.rb:83 there is select(:id) by hard
  # has_many :vms, :class_name => 'VmOpenstack', :foreign_key => :host_id
  # has_many :cloud_tenants, :through => :vms, :uniq => true

  def cloud_tenants
    CloudTenant.where(:id => vms.collect(&:cloud_tenant_id).uniq)
  end

  def ssh_users_and_passwords
    # HostOpenstackInfra is using auth key set on ext_management_system level, not individual hosts
    rl_user, auth_key = self.auth_user_keypair(:ssh_keypair)
    rl_password = nil

    # TODO(lsmola) make sudo user work. So it with be optional sudo password for private key auth, also test
    # password-less sudo
    su_user, su_password = nil, nil

    return rl_user, rl_password, su_user, su_password, {:key_data => auth_key}
  end

  def get_parent_keypair(type = nil)
    self.ext_management_system.try(:authentication_best_fit, type)
  end

  def auth_user_keypair(type = nil)
    # HostOpenstackInfra is using auth key set on ext_management_system level, not individual hosts
    cred = self.get_parent_keypair(type)
    return nil if cred.nil? || cred.userid.blank?
    [cred.userid, cred.auth_key]
  end

  def authentication_status
    self.authentication_type(:ssh_keypair).try(:status) || "None"
  end

  def update_ssh_auth_status!
    unless cred = self.authentication_type(:ssh_keypair)
      # Creating just Auth status placeholder, the credentials are stored in parent, that is EmsOpenstackInfra in this
      # case. We will create Auth per Host where we will store just state
      # TODO(lsmola) this should be done as auth inheritance, where we can override credentials on lower level, but
      # it needs to be designed first
      cred = AuthKeyPairOpenstackInfra.new(:name => "#{self.class.name} #{self.name}", :authtype => :ssh_keypair,
                                           :resource_id => id, :resource_type => 'Host')
    end

    begin
      verified = self.verify_credentials_with_ssh
    rescue StandardError, NotImplementedError
      verified = false
      $log.warn("MIQ(HostOpenstackInfra-verify_credentials_with_ssh_keypair): #{$!.inspect}")
    end

    if verified
      cred.status = 'Valid'
      cred.save
    else
      parent_keypair = self.get_parent_keypair(:ssh_keypair)
      if self.hostname && parent_keypair && parent_keypair.authtype == 'ssh_keypair'
        # The credentials on parent exists and hostname is set and we are not able to verify, go to error state
        cred.status = 'Error'
        cred.save
      else
        # Parent credentials do not exists, set None, but do not save. It will be saved as part of host, only if cred
        # already existed, so it will change state to none when parent keypair was deleted or host was powered down
        cred.status = 'None'
      end
    end
  end
end
