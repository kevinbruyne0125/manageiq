module EmbeddedAnsibleWorker::ObjectManagement
  extend ActiveSupport::Concern

  def ensure_initial_objects(provider, connection)
    ensure_organization(provider, connection)
    ensure_credential(provider, connection)
    ensure_inventory(provider, connection)
    ensure_host(provider, connection)
  end

  def remove_demo_data(connection)
    connection.api.credentials.all(:name => "Demo Credential").each(&:destroy!)
    connection.api.inventories.all(:name => "Demo Inventory").each(&:destroy!)
    connection.api.job_templates.all(:name => "Demo Job Template").each(&:destroy!)
    connection.api.projects.all(:name => "Demo Project").each(&:destroy!)
    connection.api.organizations.all(:name => "Default").each(&:destroy!)
  end

  def ensure_organization(provider, connection)
    return if provider.default_organization

    provider.default_organization = connection.api.organizations.create!(
      :name        => I18n.t("product.name"),
      :description => "#{I18n.t("product.name")} Default Organization"
    ).id
  end

  def ensure_credential(provider, connection)
    return if provider.default_credential

    provider.default_credential = connection.api.credentials.create!(
      :name         => "#{I18n.t("product.name")} Default Credential",
      :kind         => "ssh",
      :organization => provider.default_organization
    ).id
  end

  def ensure_inventory(provider, connection)
    return if provider.default_inventory

    provider.default_inventory = connection.api.inventories.create!(
      :name         => "#{I18n.t("product.name")} Default Inventory",
      :organization => provider.default_organization
    ).id
  end

  def ensure_host(provider, connection)
    return if provider.default_host

    provider.default_host = connection.api.hosts.create!(
      :name      => "localhost",
      :inventory => provider.default_inventory,
      :variables => {'ansible_connection' => "local"}.to_yaml
    ).id
  end

  CONSOLIDATED_PLUGIN_PLAYBOOKS_TEMPDIR = Pathname.new("/var/lib/awx_consolidated_source").freeze
  def ensure_plugin_playbooks_project_seeded(connection)
    clean_consolidated_plugin_directory
    copy_plugin_ansible_content

    commit_git_plugin_content

    project = existing_plugin_playbook_project(connection)
    if project
      update_playbook_project(project)
    else
      create_playbook_project(connection)
    end
  ensure
    # we already have 2 copies: one in the gem and one imported into ansible in the project, delete the temporary one
    clean_consolidated_plugin_directory
  end

  private

  def clean_consolidated_plugin_directory
    FileUtils.rm_rf(CONSOLIDATED_PLUGIN_PLAYBOOKS_TEMPDIR)
  end

  def copy_plugin_ansible_content
    FileUtils.mkdir_p(CONSOLIDATED_PLUGIN_PLAYBOOKS_TEMPDIR)

    # TODO: make this a public api via an attr_reader
    Vmdb::Plugins.instance.instance_variable_get(:@registered_ansible_content).each do |content|
      FileUtils.cp_r(Dir.glob("#{content.path}/*"), CONSOLIDATED_PLUGIN_PLAYBOOKS_TEMPDIR)
    end
  end

  def commit_git_plugin_content
    Dir.chdir(CONSOLIDATED_PLUGIN_PLAYBOOKS_TEMPDIR) do
      # ruggedize this
      `git init`
      `git add -A`
      `git commit -m "YOLO Initial Commit"`
    end
  end

  PLUGIN_PLAYBOOK_PROJECT_NAME = "Default ManageIQ Playbook Project".freeze
  PLAYBOOK_PROJECT_ATTRIBUTES = {
      :name                 => PLUGIN_PLAYBOOK_PROJECT_NAME,
      :scm_type             => "git",
      :scm_url              => "file://#{CONSOLIDATED_PLUGIN_PLAYBOOKS_TEMPDIR}",
      :scm_update_on_launch => false
  }.freeze

  def existing_plugin_playbook_project(connection)
    connection.api.projects.all(:name => PLUGIN_PLAYBOOK_PROJECT_NAME).first
  end

  def update_playbook_project(project)
    project.update_attributes!(PLAYBOOK_PROJECT_ATTRIBUTES)
  end

  def create_playbook_project(connection)
    connection.api.projects.create!(PLAYBOOK_PROJECT_ATTRIBUTES.to_json)
  end
end
