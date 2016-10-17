class GitBasedDomainImportService
  def queue_import(git_repo_id, branch_or_tag, tenant_id)
    git_repo = GitRepository.find_by(:id => git_repo_id)

    ref_type = if git_repo.git_branches.any? { |git_branch| git_branch.name == branch_or_tag }
                 "branch"
               else
                 "tag"
               end

    import_options = {
      "git_repository_id" => git_repo.id,
      "ref"               => branch_or_tag,
      "ref_type"          => ref_type,
      "tenant_id"         => tenant_id
    }

    task_options = {
      :action => "Import git repository",
      :userid => User.current_user.userid
    }

    queue_options = {
        :class_name  => "MiqAeDomain",
        :method_name => "import_git_repo",
        :role        => "git_owner",
        :args        => [import_options]
    }

    MiqTask.generic_action_with_callback(task_options, queue_options)
  end

  def import(git_repo_id, branch_or_tag, tenant_id)
    task_id = queue_import(git_repo_id, branch_or_tag, tenant_id)
    task = MiqTask.wait_for_taskid(task_id)

    domain = task.task_results
    domain.update_attribute(:enabled, true)
  end

  def self.available?
    MiqRegion.my_region.role_active?("git_owner")
  end
end
