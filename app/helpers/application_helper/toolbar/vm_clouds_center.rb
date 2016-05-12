class ApplicationHelper::Toolbar::VmCloudsCenter < ApplicationHelper::Toolbar::Basic
  button_group('instance_vmdb', [
    select(
      :instance_vmdb_choice,
      'fa fa-cog fa-lg',
      t = N_('Configuration'),
      t,
      :enabled => false,
      :onwhen  => "1+",
      :items   => [
        button(
          :instance_refresh,
          'fa fa-refresh fa-lg',
          N_('Refresh relationships and power states for all items related to the selected items'),
          N_('Refresh Relationships and Power States'),
          :url_parms => "main_div",
          :confirm   => N_("Refresh relationships and power states for all items related to the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_scan,
          'fa fa-search fa-lg',
          N_('Perform SmartState Analysis on the selected items'),
          N_('Perform SmartState Analysis'),
          :url_parms => "main_div",
          :confirm   => N_("Perform SmartState Analysis on the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_compare,
          'product product-compare fa-lg',
          N_('Select two or more items to compare'),
          N_('Compare Selected items'),
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "2+"),
        separator,
        button(
          :instance_edit,
          'pficon pficon-edit fa-lg',
          N_('Select a single item to edit'),
          N_('Edit Selected item'),
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "1"),
        button(
          :instance_ownership,
          'pficon pficon-user fa-lg',
          N_('Set Ownership for the selected items'),
          N_('Set Ownership'),
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "1+"),
        separator,
        button(
          :instance_delete,
          'pficon pficon-delete fa-lg',
          t = N_('Remove selected items from the VMDB'),
          t,
          :url_parms => "main_div",
          :confirm   => N_("Warning: The selected items and ALL of their components will be permanently removed from the Virtual Management Database.  Are you sure you want to remove the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        separator,
        button(
          :instance_resize,
          'pficon pficon-edit fa-lg',
          t = N_('Reconfigure selected Instance'),
          t,
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "1")
      ]
    ),
  ])
  button_group('instance_policy', [
    select(
      :instance_policy_choice,
      'fa fa-shield fa-lg',
      t = N_('Policy'),
      t,
      :enabled => false,
      :onwhen  => "1+",
      :items   => [
        button(
          :instance_protect,
          'pficon pficon-edit fa-lg',
          N_('Manage Policies for the selected items'),
          N_('Manage Policies'),
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_policy_sim,
          'fa fa-play-circle-o fa-lg',
          N_('View Policy Simulation for the selected items'),
          N_('Policy Simulation'),
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_tag,
          'pficon pficon-edit fa-lg',
          N_('Edit tags for the selected items'),
          N_('Edit Tags'),
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_check_compliance,
          'fa fa-search fa-lg',
          N_('Check Compliance of the last known configuration for the selected items'),
          N_('Check Compliance of Last Known Configuration'),
          :url_parms => "main_div",
          :confirm   => N_("Initiate Check Compliance of the last known configuration for the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
      ]
    ),
  ])
  button_group('instance_lifecycle', [
    select(
      :instance_lifecycle_choice,
      'fa fa-recycle fa-lg',
      t = N_('Lifecycle'),
      t,
      :items => [
        button(
          :instance_miq_request_new,
          'pficon pficon-add-circle-o fa-lg',
          N_('Request to Provision Instances'),
          N_('Provision Instances'),
          :url_parms => "main_div"),
        button(
          :instance_retire,
          'fa fa-clock-o fa-lg',
          N_('Set Retirement Dates for the selected items'),
          N_('Set Retirement Dates'),
          :url_parms => "main_div",
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_retire_now,
          'fa fa-clock-o fa-lg',
          N_('Retire the selected items'),
          N_('Retire selected items'),
          :url_parms => "main_div",
          :confirm   => N_("Retire the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_live_migrate,
          'product product-migrate fa-lg',
          t = N_('Migrate selected Instance'),
          t,
          :url_parms => 'main_div',
          :enabled   => false,
          :onwhen    => '1'),
        button(
          :instance_evacuate,
          'product product-evacuate fa-lg',
          t = N_('Evacuate selected Instance'),
          t,
          :url_parms => 'main_div',
          :enabled   => false,
          :onwhen    => '1')
      ]
    ),
  ])
  button_group('instance_operations', [
    select(
      :instance_power_choice,
      'fa fa-power-off fa-lg',
      N_('Power Operations'),
      N_('Power'),
      :enabled => false,
      :onwhen  => "1+",
      :items   => [
        button(
          :instance_stop,
          nil,
          N_('Stop the selected items'),
          N_('Stop'),
          :image     => "guest_shutdown",
          :url_parms => "main_div",
          :confirm   => N_("Stop the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_start,
          nil,
          N_('Start the selected items'),
          N_('Start'),
          :image     => "power_on",
          :url_parms => "main_div",
          :confirm   => N_("Start the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_pause,
          nil,
          N_('Pause the selected items'),
          N_('Pause'),
          :image     => "power_pause",
          :url_parms => "main_div",
          :confirm   => N_("Pause the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_suspend,
          nil,
          N_('Suspend the selected items'),
          N_('Suspend'),
          :image     => "suspend",
          :url_parms => "main_div",
          :confirm   => N_("Suspend the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_shelve,
          nil,
          N_('Shelve the selected items'),
          N_('Shelve'),
          :image     => "power_shelve",
          :url_parms => "main_div",
          :confirm   => N_("Shelve the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_shelve_offload,
          nil,
          N_('Shelve Offload the selected items'),
          N_('Shelve Offload'),
          :image     => "power_shelve_offload",
          :url_parms => "main_div",
          :confirm   => N_("Shelve Offload the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_resume,
          nil,
          N_('Resume the selected items'),
          N_('Resume'),
          :image     => "power_resume",
          :url_parms => "main_div",
          :confirm   => N_("Resume the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        separator,
        button(
          :instance_guest_restart,
          nil,
          N_('Soft Reboot the selected items'),
          N_('Soft Reboot'),
          :image     => "power_reset",
          :url_parms => "main_div",
          :confirm   => N_("Soft Reboot the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_reset,
          nil,
          N_('Hard Reboot the Guest OS on the selected items'),
          N_('Hard Reboot'),
          :image     => "guest_restart",
          :url_parms => "main_div",
          :confirm   => N_("Hard Reboot the Guest OS on the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
        button(
          :instance_terminate,
          nil,
          N_('Terminate the selected items'),
          N_('Terminate'),
          :image     => "power_off",
          :url_parms => "main_div",
          :confirm   => N_("Terminate the selected items?"),
          :enabled   => false,
          :onwhen    => "1+"),
      ]
    ),
  ])
end
