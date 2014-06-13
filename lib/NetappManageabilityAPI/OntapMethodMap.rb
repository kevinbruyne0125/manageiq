
module OntapMethodMap
	
	MehodMap = {
		:aggr_add	=>	"aggr-add",
		:aggr_check_spare_low	=>	"aggr-check-spare-low",
		:aggr_create	=>	"aggr-create",
		:aggr_destroy	=>	"aggr-destroy",
		:aggr_get_filer_info	=>	"aggr-get-filer-info",
		:aggr_get_root_name	=>	"aggr-get-root-name",
		:aggr_list_info	=>	"aggr-list-info",
		:aggr_mediascrub_list_info	=>	"aggr-mediascrub-list-info",
		:aggr_mirror	=>	"aggr-mirror",
		:aggr_offline	=>	"aggr-offline",
		:aggr_online	=>	"aggr-online",
		:aggr_options_list_info	=>	"aggr-options-list-info",
		:aggr_rename	=>	"aggr-rename",
		:aggr_restrict	=>	"aggr-restrict",
		:aggr_scrub_list_info	=>	"aggr-scrub-list-info",
		:aggr_scrub_resume	=>	"aggr-scrub-resume",
		:aggr_scrub_start	=>	"aggr-scrub-start",
		:aggr_scrub_stop	=>	"aggr-scrub-stop",
		:aggr_scrub_suspend	=>	"aggr-scrub-suspend",
		:aggr_set_option	=>	"aggr-set-option",
		:aggr_space_list_info	=>	"aggr-space-list-info",
		:aggr_split	=>	"aggr-split",
		:aggr_verify_list_info	=>	"aggr-verify-list-info",
		:aggr_verify_resume	=>	"aggr-verify-resume",
		:aggr_verify_start	=>	"aggr-verify-start",
		:aggr_verify_stop	=>	"aggr-verify-stop",
		:aggr_verify_suspend	=>	"aggr-verify-suspend",
		:cf_force_takeover	=>	"cf-force-takeover",
		:cf_get_partner	=>	"cf-get-partner",
		:cf_giveback	=>	"cf-giveback",
		:cf_hwassist_stats	=>	"cf-hwassist-stats",
		:cf_hwassist_status	=>	"cf-hwassist-status",
		:cf_negotiated_failover_disable	=>	"cf-negotiated-failover-disable",
		:cf_negotiated_failover_enable	=>	"cf-negotiated-failover-enable",
		:cf_negotiated_failover_status	=>	"cf-negotiated-failover-status",
		:cf_service_disable	=>	"cf-service-disable",
		:cf_service_enable	=>	"cf-service-enable",
		:cf_status	=>	"cf-status",
		:cf_takeover	=>	"cf-takeover",
		:cifs_homedir_path_get_for_user	=>	"cifs-homedir-path-get-for-user",
		:cifs_homedir_paths_get	=>	"cifs-homedir-paths-get",
		:cifs_homedir_paths_set	=>	"cifs-homedir-paths-set",
		:cifs_list_config	=>	"cifs-list-config",
		:cifs_nbalias_names_get	=>	"cifs-nbalias-names-get",
		:cifs_nbalias_names_set	=>	"cifs-nbalias-names-set",
		:cifs_session_list_iter_end	=>	"cifs-session-list-iter-end",
		:cifs_session_list_iter_next	=>	"cifs-session-list-iter-next",
		:cifs_session_list_iter_start	=>	"cifs-session-list-iter-start",
		:cifs_setup	=>	"cifs-setup",
		:cifs_setup_create_group_file	=>	"cifs-setup-create-group-file",
		:cifs_setup_create_passwd_file	=>	"cifs-setup-create-passwd-file",
		:cifs_setup_ou_list_iter_end	=>	"cifs-setup-ou-list-iter-end",
		:cifs_setup_ou_list_iter_next	=>	"cifs-setup-ou-list-iter-next",
		:cifs_setup_ou_list_iter_start	=>	"cifs-setup-ou-list-iter-start",
		:cifs_setup_site_list_iter_end	=>	"cifs-setup-site-list-iter-end",
		:cifs_setup_site_list_iter_next	=>	"cifs-setup-site-list-iter-next",
		:cifs_setup_site_list_iter_start	=>	"cifs-setup-site-list-iter-start",
		:cifs_setup_verify_name	=>	"cifs-setup-verify-name",
		:cifs_setup_verify_passwd_and_group	=>	"cifs-setup-verify-passwd-and-group",
		:cifs_share_ace_delete	=>	"cifs-share-ace-delete",
		:cifs_share_ace_set	=>	"cifs-share-ace-set",
		:cifs_share_acl_list_iter_end	=>	"cifs-share-acl-list-iter-end",
		:cifs_share_acl_list_iter_next	=>	"cifs-share-acl-list-iter-next",
		:cifs_share_acl_list_iter_start	=>	"cifs-share-acl-list-iter-start",
		:cifs_share_add	=>	"cifs-share-add",
		:cifs_share_change	=>	"cifs-share-change",
		:cifs_share_delete	=>	"cifs-share-delete",
		:cifs_share_list_iter_end	=>	"cifs-share-list-iter-end",
		:cifs_share_list_iter_next	=>	"cifs-share-list-iter-next",
		:cifs_share_list_iter_start	=>	"cifs-share-list-iter-start",
		:cifs_start	=>	"cifs-start",
		:cifs_status	=>	"cifs-status",
		:cifs_stop	=>	"cifs-stop",
		:cifs_top_iter_end	=>	"cifs-top-iter-end",
		:cifs_top_iter_next	=>	"cifs-top-iter-next",
		:cifs_top_iter_start	=>	"cifs-top-iter-start",
		:clock_get_clock	=>	"clock-get-clock",
		:clock_get_timezone	=>	"clock-get-timezone",
		:clock_set_clock	=>	"clock-set-clock",
		:clock_set_timezone	=>	"clock-set-timezone",
		:clone_clear	=>	"clone-clear",
		:clone_list_status	=>	"clone-list-status",
		:clone_start	=>	"clone-start",
		:clone_stop	=>	"clone-stop",
		:cg_commit	=>	"cg-commit",
		:cg_delete	=>	"cg-delete",
		:cg_start	=>	"cg-start",
		:dfm_get_server_info	=>	"dfm-get-server-info",
		:dfm_set_server_info	=>	"dfm-set-server-info",
		:disk_fail	=>	"disk-fail",
		:disk_list_info	=>	"disk-list-info",
		:disk_release_all_reservations	=>	"disk-release-all-reservations",
		:disk_remove	=>	"disk-remove",
		:disk_replace_start	=>	"disk-replace-start",
		:disk_replace_stop	=>	"disk-replace-stop",
		:disk_sanown_assign	=>	"disk-sanown-assign",
		:disk_sanown_filer_list_info	=>	"disk-sanown-filer-list-info",
		:disk_sanown_list_info	=>	"disk-sanown-list-info",
		:disk_sanown_reassign	=>	"disk-sanown-reassign",
		:disk_sanown_remove_ownership	=>	"disk-sanown-remove-ownership",
		:disk_swap	=>	"disk-swap",
		:disk_unfail	=>	"disk-unfail",
		:disk_unswap	=>	"disk-unswap",
		:disk_update_disk_fw	=>	"disk-update-disk-fw",
		:disk_zero_spares	=>	"disk-zero-spares",
		:ems_autosupport_log	=>	"ems-autosupport-log",
		:ems_invoke	=>	"ems-invoke",
		:fc_config_adapter_disable	=>	"fc-config-adapter-disable",
		:fc_config_adapter_enable	=>	"fc-config-adapter-enable",
		:fc_config_list_iter_end	=>	"fc-config-list-iter-end",
		:fc_config_list_iter_next	=>	"fc-config-list-iter-next",
		:fc_config_list_iter_start	=>	"fc-config-list-iter-start",
		:fc_config_set_adapter_fc_type	=>	"fc-config-set-adapter-fc-type",
		:fcp_adapter_clear_partner	=>	"fcp-adapter-clear-partner",
		:fcp_adapter_config_down	=>	"fcp-adapter-config-down",
		:fcp_adapter_config_media_type	=>	"fcp-adapter-config-media-type",
		:fcp_adapter_config_up	=>	"fcp-adapter-config-up",
		:fcp_adapter_initiators_list_info	=>	"fcp-adapter-initiators-list-info",
		:fcp_adapter_list_info	=>	"fcp-adapter-list-info",
		:fcp_adapter_reset_stats	=>	"fcp-adapter-reset-stats",
		:fcp_adapter_set_partner	=>	"fcp-adapter-set-partner",
		:fcp_adapter_set_speed	=>	"fcp-adapter-set-speed",
		:fcp_adapter_stats_list_info	=>	"fcp-adapter-stats-list-info",
		:fcp_get_cfmode	=>	"fcp-get-cfmode",
		:fcp_node_get_name	=>	"fcp-node-get-name",
		:fcp_node_set_name	=>	"fcp-node-set-name",
		:fcp_port_name_list_info	=>	"fcp-port-name-list-info",
		:fcp_port_name_set	=>	"fcp-port-name-set",
		:fcp_port_name_swap	=>	"fcp-port-name-swap",
		:fcp_service_start	=>	"fcp-service-start",
		:fcp_service_status	=>	"fcp-service-status",
		:fcp_service_stop	=>	"fcp-service-stop",
		:fcp_set_cfmode	=>	"fcp-set-cfmode",
		:fcp_wwpnalias_get_alias_info	=>	"fcp-wwpnalias-get-alias-info",
		:fcp_wwpnalias_remove	=>	"fcp-wwpnalias-remove",
		:fcp_wwpnalias_set	=>	"fcp-wwpnalias-set",
		:fcport_get_link_state	=>	"fcport-get-link-state",
		:fcport_reset_dev	=>	"fcport-reset-dev",
		:fcport_send_lip	=>	"fcport-send-lip",
		:fcport_set_offline	=>	"fcport-set-offline",
		:fcport_set_online	=>	"fcport-set-online",
		:file_create_directory	=>	"file-create-directory",
		:file_create_symlink	=>	"file-create-symlink",
		:file_delete_directory	=>	"file-delete-directory",
		:file_delete_file	=>	"file-delete-file",
		:file_get_file_info	=>	"file-get-file-info",
		:file_get_fingerprint	=>	"file-get-fingerprint",
		:file_inode_info	=>	"file-inode-info",
		:file_list_directory_iter_end	=>	"file-list-directory-iter-end",
		:file_list_directory_iter_next	=>	"file-list-directory-iter-next",
		:file_list_directory_iter_start	=>	"file-list-directory-iter-start",
		:file_read_file	=>	"file-read-file",
		:file_read_symlink	=>	"file-read-symlink",
		:file_rename_directory	=>	"file-rename-directory",
		:file_truncate_file	=>	"file-truncate-file",
		:file_write_file	=>	"file-write-file",
		:fpolicy_create_policy	=>	"fpolicy-create-policy",
		:fpolicy_destroy_policy	=>	"fpolicy-destroy-policy",
		:fpolicy_disable	=>	"fpolicy-disable",
		:fpolicy_disable_policy	=>	"fpolicy-disable-policy",
		:fpolicy_enable	=>	"fpolicy-enable",
		:fpolicy_enable_policy	=>	"fpolicy-enable-policy",
		:fpolicy_extensions	=>	"fpolicy-extensions",
		:fpolicy_extensions_list_info	=>	"fpolicy-extensions-list-info",
		:fpolicy_get_policy_options	=>	"fpolicy-get-policy-options",
		:fpolicy_get_required_info	=>	"fpolicy-get-required-info",
		:fpolicy_get_secondary_servers_info	=>	"fpolicy-get-secondary-servers-info",
		:fpolicy_list_info	=>	"fpolicy-list-info",
		:fpolicy_operations_list_set	=>	"fpolicy-operations-list-set",
		:fpolicy_server_list_info	=>	"fpolicy-server-list-info",
		:fpolicy_server_stop	=>	"fpolicy-server-stop",
		:fpolicy_set_policy_options	=>	"fpolicy-set-policy-options",
		:fpolicy_set_required	=>	"fpolicy-set-required",
		:fpolicy_set_secondary_servers	=>	"fpolicy-set-secondary-servers",
		:fpolicy_status	=>	"fpolicy-status",
		:fpolicy_volume_list_info	=>	"fpolicy-volume-list-info",
		:fpolicy_volume_list_set	=>	"fpolicy-volume-list-set",
		:ic_get_error_stats	=>	"ic-get-error-stats",
		:ic_get_perf_stats	=>	"ic-get-perf-stats",
		:ic_get_queue_info	=>	"ic-get-queue-info",
		:ic_zero_error_stats	=>	"ic-zero-error-stats",
		:igroup_add	=>	"igroup-add",
		:igroup_bind_portset	=>	"igroup-bind-portset",
		:igroup_create	=>	"igroup-create",
		:igroup_destroy	=>	"igroup-destroy",
		:igroup_list_info	=>	"igroup-list-info",
		:igroup_lookup_lun	=>	"igroup-lookup-lun",
		:igroup_remove	=>	"igroup-remove",
		:igroup_rename	=>	"igroup-rename",
		:igroup_set_attribute	=>	"igroup-set-attribute",
		:igroup_unbind_portset	=>	"igroup-unbind-portset",
		:ipspace_list_info	=>	"ipspace-list-info",
		:iscsi_adapter_config_down	=>	"iscsi-adapter-config-down",
		:iscsi_adapter_config_up	=>	"iscsi-adapter-config-up",
		:iscsi_adapter_initiators_list_info	=>	"iscsi-adapter-initiators-list-info",
		:iscsi_adapter_list_info	=>	"iscsi-adapter-list-info",
		:iscsi_adapter_reset_stats	=>	"iscsi-adapter-reset-stats",
		:iscsi_adapter_stats_list_info	=>	"iscsi-adapter-stats-list-info",
		:iscsi_auth_generate_chap_password	=>	"iscsi-auth-generate-chap-password",
		:iscsi_connection_list_info	=>	"iscsi-connection-list-info",
		:iscsi_initiator_add_auth	=>	"iscsi-initiator-add-auth",
		:iscsi_initiator_auth_list_info	=>	"iscsi-initiator-auth-list-info",
		:iscsi_initiator_delete_auth	=>	"iscsi-initiator-delete-auth",
		:iscsi_initiator_get_auth	=>	"iscsi-initiator-get-auth",
		:iscsi_initiator_get_default_auth	=>	"iscsi-initiator-get-default-auth",
		:iscsi_initiator_list_info	=>	"iscsi-initiator-list-info",
		:iscsi_initiator_modify_chap_params	=>	"iscsi-initiator-modify-chap-params",
		:iscsi_initiator_set_default_auth	=>	"iscsi-initiator-set-default-auth",
		:iscsi_interface_disable	=>	"iscsi-interface-disable",
		:iscsi_interface_enable	=>	"iscsi-interface-enable",
		:iscsi_interface_list_info	=>	"iscsi-interface-list-info",
		:iscsi_isns_config	=>	"iscsi-isns-config",
		:iscsi_isns_get_info	=>	"iscsi-isns-get-info",
		:iscsi_isns_start	=>	"iscsi-isns-start",
		:iscsi_isns_stop	=>	"iscsi-isns-stop",
		:iscsi_isns_update	=>	"iscsi-isns-update",
		:iscsi_node_get_name	=>	"iscsi-node-get-name",
		:iscsi_node_set_name	=>	"iscsi-node-set-name",
		:iscsi_portal_list_info	=>	"iscsi-portal-list-info",
		:iscsi_reset_stats	=>	"iscsi-reset-stats",
		:iscsi_service_start	=>	"iscsi-service-start",
		:iscsi_service_status	=>	"iscsi-service-status",
		:iscsi_service_stop	=>	"iscsi-service-stop",
		:iscsi_session_list_info	=>	"iscsi-session-list-info",
		:iscsi_stats_list_info	=>	"iscsi-stats-list-info",
		:iscsi_target_alias_clear_alias	=>	"iscsi-target-alias-clear-alias",
		:iscsi_target_alias_get_alias	=>	"iscsi-target-alias-get-alias",
		:iscsi_target_alias_set_alias	=>	"iscsi-target-alias-set-alias",
		:iscsi_tpgroup_alua_set	=>	"iscsi-tpgroup-alua-set",
		:iscsi_tpgroup_create	=>	"iscsi-tpgroup-create",
		:iscsi_tpgroup_destroy	=>	"iscsi-tpgroup-destroy",
		:iscsi_tpgroup_interface_add	=>	"iscsi-tpgroup-interface-add",
		:iscsi_tpgroup_interface_delete	=>	"iscsi-tpgroup-interface-delete",
		:iscsi_tpgroup_list_info	=>	"iscsi-tpgroup-list-info",
		:license_add	=>	"license-add",
		:license_delete	=>	"license-delete",
		:license_list_info	=>	"license-list-info",
		:lock_break	=>	"lock-break",
		:lock_status_iter_end	=>	"lock-status-iter-end",
		:lock_status_iter_next	=>	"lock-status-iter-next",
		:lock_status_iter_start	=>	"lock-status-iter-start",
		:file_get_space_reservation_info	=>	"file-get-space-reservation-info",
		:file_set_space_reservation_info	=>	"file-set-space-reservation-info",
		:lun_clear_persistent_reservation_info	=>	"lun-clear-persistent-reservation-info",
		:lun_clone_list_info	=>	"lun-clone-list-info",
		:lun_clone_split_start	=>	"lun-clone-split-start",
		:lun_clone_split_status_list_info	=>	"lun-clone-split-status-list-info",
		:lun_clone_split_stop	=>	"lun-clone-split-stop",
		:lun_clone_start	=>	"lun-clone-start",
		:lun_clone_status_list_info	=>	"lun-clone-status-list-info",
		:lun_clone_stop	=>	"lun-clone-stop",
		:lun_config_check_alua_conflicts_info	=>	"lun-config-check-alua-conflicts-info",
		:lun_config_check_cfmode_info	=>	"lun-config-check-cfmode-info",
		:lun_config_check_info	=>	"lun-config-check-info",
		:lun_config_check_single_image_info	=>	"lun-config-check-single-image-info",
		:lun_create_by_size	=>	"lun-create-by-size",
		:lun_create_clone	=>	"lun-create-clone",
		:lun_create_from_file	=>	"lun-create-from-file",
		:lun_create_from_snapshot	=>	"lun-create-from-snapshot",
		:lun_destroy	=>	"lun-destroy",
		:lun_get_attribute	=>	"lun-get-attribute",
		:lun_get_comment	=>	"lun-get-comment",
		:lun_get_geometry	=>	"lun-get-geometry",
		:lun_get_inquiry_info	=>	"lun-get-inquiry-info",
		:lun_get_maxsize	=>	"lun-get-maxsize",
		:lun_get_minsize	=>	"lun-get-minsize",
		:lun_get_occupied_size	=>	"lun-get-occupied-size",
		:lun_get_persistent_reservation_info	=>	"lun-get-persistent-reservation-info",
		:lun_get_select_attribute	=>	"lun-get-select-attribute",
		:lun_get_serial_number	=>	"lun-get-serial-number",
		:lun_get_space_reservation_info	=>	"lun-get-space-reservation-info",
		:lun_get_vdisk_attributes	=>	"lun-get-vdisk-attributes",
		:lun_has_scsi_reservations	=>	"lun-has-scsi-reservations",
		:lun_initiator_list_map_info	=>	"lun-initiator-list-map-info",
		:lun_initiator_logged_in	=>	"lun-initiator-logged-in",
		:lun_list_info	=>	"lun-list-info",
		:lun_map	=>	"lun-map",
		:lun_map_list_info	=>	"lun-map-list-info",
		:lun_move	=>	"lun-move",
		:lun_offline	=>	"lun-offline",
		:lun_online	=>	"lun-online",
		:lun_port_has_scsi_reservations	=>	"lun-port-has-scsi-reservations",
		:lun_reset_stats	=>	"lun-reset-stats",
		:lun_resize	=>	"lun-resize",
		:lun_restore_status	=>	"lun-restore-status",
		:lun_set_attribute	=>	"lun-set-attribute",
		:lun_set_comment	=>	"lun-set-comment",
		:lun_set_device_id	=>	"lun-set-device-id",
		:lun_set_select_attribute	=>	"lun-set-select-attribute",
		:lun_set_serial_number	=>	"lun-set-serial-number",
		:lun_set_share	=>	"lun-set-share",
		:lun_set_space_reservation_info	=>	"lun-set-space-reservation-info",
		:lun_snap_usage_list_info	=>	"lun-snap-usage-list-info",
		:lun_stats_list_info	=>	"lun-stats-list-info",
		:lun_unmap	=>	"lun-unmap",
		:lun_unset_attribute	=>	"lun-unset-attribute",
		:lun_unset_device_id	=>	"lun-unset-device-id",
		:nameservice_map_gid_to_group_name	=>	"nameservice-map-gid-to-group-name",
		:nameservice_map_group_name_to_gid	=>	"nameservice-map-group-name-to-gid",
		:nameservice_map_sid_to_uid	=>	"nameservice-map-sid-to-uid",
		:nameservice_map_uid_to_user_name	=>	"nameservice-map-uid-to-user-name",
		:nameservice_map_unix_to_windows	=>	"nameservice-map-unix-to-windows",
		:nameservice_map_user_name_to_uid	=>	"nameservice-map-user-name-to-uid",
		:nameservice_map_windows_to_unix	=>	"nameservice-map-windows-to-unix",
		:net_config_get_active	=>	"net-config-get-active",
		:net_config_get_persistent	=>	"net-config-get-persistent",
		:net_config_set_persistent	=>	"net-config-set-persistent",
		:net_ifconfig_get	=>	"net-ifconfig-get",
		:net_ifconfig_set	=>	"net-ifconfig-set",
		:net_ipspace_assign	=>	"net-ipspace-assign",
		:net_ipspace_create	=>	"net-ipspace-create",
		:net_ipspace_destroy	=>	"net-ipspace-destroy",
		:net_ipspace_list	=>	"net-ipspace-list",
		:net_ping	=>	"net-ping",
		:net_ping_info	=>	"net-ping-info",
		:net_resolve	=>	"net-resolve",
		:net_route_add	=>	"net-route-add",
		:net_route_delete	=>	"net-route-delete",
		:net_vlan_create	=>	"net-vlan-create",
		:net_vlan_delete	=>	"net-vlan-delete",
		:nfs_disable	=>	"nfs-disable",
		:nfs_enable	=>	"nfs-enable",
		:nfs_exportfs_append_rules	=>	"nfs-exportfs-append-rules",
		:nfs_exportfs_append_rules_2	=>	"nfs-exportfs-append-rules-2",
		:nfs_exportfs_check_permission	=>	"nfs-exportfs-check-permission",
		:nfs_exportfs_delete_rules	=>	"nfs-exportfs-delete-rules",
		:nfs_exportfs_fence_disable	=>	"nfs-exportfs-fence-disable",
		:nfs_exportfs_fence_enable	=>	"nfs-exportfs-fence-enable",
		:nfs_exportfs_flush_cache	=>	"nfs-exportfs-flush-cache",
		:nfs_exportfs_list_rules	=>	"nfs-exportfs-list-rules",
		:nfs_exportfs_list_rules_2	=>	"nfs-exportfs-list-rules-2",
		:nfs_exportfs_load_exports	=>	"nfs-exportfs-load-exports",
		:nfs_exportfs_modify_rule	=>	"nfs-exportfs-modify-rule",
		:nfs_exportfs_modify_rule_2	=>	"nfs-exportfs-modify-rule-2",
		:nfs_exportfs_storage_path	=>	"nfs-exportfs-storage-path",
		:nfs_get_supported_sec_flavors	=>	"nfs-get-supported-sec-flavors",
		:nfs_monitor_add	=>	"nfs-monitor-add",
		:nfs_monitor_list	=>	"nfs-monitor-list",
		:nfs_monitor_reclaim	=>	"nfs-monitor-reclaim",
		:nfs_monitor_remove	=>	"nfs-monitor-remove",
		:nfs_monitor_remove_locks	=>	"nfs-monitor-remove-locks",
		:nfs_stats_get_client_stats	=>	"nfs-stats-get-client-stats",
		:nfs_stats_top_clients_list_iter_end	=>	"nfs-stats-top-clients-list-iter-end",
		:nfs_stats_top_clients_list_iter_next	=>	"nfs-stats-top-clients-list-iter-next",
		:nfs_stats_top_clients_list_iter_start	=>	"nfs-stats-top-clients-list-iter-start",
		:nfs_stats_zero_stats	=>	"nfs-stats-zero-stats",
		:nfs_status	=>	"nfs-status",
		:options_get	=>	"options-get",
		:options_list_info	=>	"options-list-info",
		:options_set	=>	"options-set",
		:perf_object_counter_list_info	=>	"perf-object-counter-list-info",
		:perf_object_get_instances	=>	"perf-object-get-instances",
		:perf_object_get_instances_iter_end	=>	"perf-object-get-instances-iter-end",
		:perf_object_get_instances_iter_next	=>	"perf-object-get-instances-iter-next",
		:perf_object_get_instances_iter_start	=>	"perf-object-get-instances-iter-start",
		:perf_object_instance_list_info	=>	"perf-object-instance-list-info",
		:perf_object_instance_list_info_iter_end	=>	"perf-object-instance-list-info-iter-end",
		:perf_object_instance_list_info_iter_next	=>	"perf-object-instance-list-info-iter-next",
		:perf_object_instance_list_info_iter_start	=>	"perf-object-instance-list-info-iter-start",
		:perf_object_list_info	=>	"perf-object-list-info",
		:portset_add	=>	"portset-add",
		:portset_create	=>	"portset-create",
		:portset_destroy	=>	"portset-destroy",
		:portset_list_info	=>	"portset-list-info",
		:portset_remove	=>	"portset-remove",
		:priority_disable	=>	"priority-disable",
		:priority_enable	=>	"priority-enable",
		:priority_list_info	=>	"priority-list-info",
		:priority_list_info_default	=>	"priority-list-info-default",
		:priority_list_info_volume	=>	"priority-list-info-volume",
		:priority_set	=>	"priority-set",
		:priority_set_default	=>	"priority-set-default",
		:priority_set_volume	=>	"priority-set-volume",
		:qtree_create	=>	"qtree-create",
		:qtree_delete	=>	"qtree-delete",
		:qtree_list	=>	"qtree-list",
		:qtree_list_iter_end	=>	"qtree-list-iter-end",
		:qtree_list_iter_next	=>	"qtree-list-iter-next",
		:qtree_list_iter_start	=>	"qtree-list-iter-start",
		:qtree_rename	=>	"qtree-rename",
		:quota_add_entry	=>	"quota-add-entry",
		:quota_delete_entry	=>	"quota-delete-entry",
		:quota_get_entry	=>	"quota-get-entry",
		:quota_list_entries	=>	"quota-list-entries",
		:quota_list_entries_iter_end	=>	"quota-list-entries-iter-end",
		:quota_list_entries_iter_next	=>	"quota-list-entries-iter-next",
		:quota_list_entries_iter_start	=>	"quota-list-entries-iter-start",
		:quota_modify_entry	=>	"quota-modify-entry",
		:quota_off	=>	"quota-off",
		:quota_on	=>	"quota-on",
		:quota_report	=>	"quota-report",
		:quota_report_iter_end	=>	"quota-report-iter-end",
		:quota_report_iter_next	=>	"quota-report-iter-next",
		:quota_report_iter_start	=>	"quota-report-iter-start",
		:quota_resize	=>	"quota-resize",
		:quota_set_entry	=>	"quota-set-entry",
		:quota_status	=>	"quota-status",
		:reallocate_delete_schedule	=>	"reallocate-delete-schedule",
		:reallocate_list_info	=>	"reallocate-list-info",
		:reallocate_measure	=>	"reallocate-measure",
		:reallocate_off	=>	"reallocate-off",
		:reallocate_on	=>	"reallocate-on",
		:reallocate_quiesce	=>	"reallocate-quiesce",
		:reallocate_restart	=>	"reallocate-restart",
		:reallocate_set_schedule	=>	"reallocate-set-schedule",
		:reallocate_start	=>	"reallocate-start",
		:reallocate_stop	=>	"reallocate-stop",
		:rsh_get_stats	=>	"rsh-get-stats",
		:rsh_kill	=>	"rsh-kill",
		:storage_shelf_environment_list_info	=>	"storage-shelf-environment-list-info",
		:storage_shelf_list_info	=>	"storage-shelf-list-info",
		:storage_shelf_set_led_state	=>	"storage-shelf-set-led-state",
		:storage_shelf_update_fw	=>	"storage-shelf-update-fw",
		:sis_disable	=>	"sis-disable",
		:sis_enable	=>	"sis-enable",
		:sis_set_config	=>	"sis-set-config",
		:sis_start	=>	"sis-start",
		:sis_status	=>	"sis-status",
		:sis_stop	=>	"sis-stop",
		:file_get_snaplock_retention_time	=>	"file-get-snaplock-retention-time",
		:file_get_snaplock_retention_time_list_info_max	=>	"file-get-snaplock-retention-time-list-info-max",
		:file_set_snaplock_retention_time	=>	"file-set-snaplock-retention-time",
		:file_snaplock_retention_time_list_info	=>	"file-snaplock-retention-time-list-info",
		:snaplock_get_compliance_clock	=>	"snaplock-get-compliance-clock",
		:snaplock_get_log_volume	=>	"snaplock-get-log-volume",
		:snaplock_get_options	=>	"snaplock-get-options",
		:snaplock_log_archive	=>	"snaplock-log-archive",
		:snaplock_log_status_list_info	=>	"snaplock-log-status-list-info",
		:snaplock_privileged_delete_file	=>	"snaplock-privileged-delete-file",
		:snaplock_set_log_volume	=>	"snaplock-set-log-volume",
		:snaplock_set_options	=>	"snaplock-set-options",
		:snapmirror_abort	=>	"snapmirror-abort",
		:snapmirror_break	=>	"snapmirror-break",
		:snapmirror_delete_connection	=>	"snapmirror-delete-connection",
		:snapmirror_delete_schedule	=>	"snapmirror-delete-schedule",
		:snapmirror_delete_sync_schedule	=>	"snapmirror-delete-sync-schedule",
		:snapmirror_get_status	=>	"snapmirror-get-status",
		:snapmirror_get_volume_status	=>	"snapmirror-get-volume-status",
		:snapmirror_initialize	=>	"snapmirror-initialize",
		:snapmirror_list_connections	=>	"snapmirror-list-connections",
		:snapmirror_list_destinations	=>	"snapmirror-list-destinations",
		:snapmirror_list_schedule	=>	"snapmirror-list-schedule",
		:snapmirror_list_sync_schedule	=>	"snapmirror-list-sync-schedule",
		:snapmirror_off	=>	"snapmirror-off",
		:snapmirror_on	=>	"snapmirror-on",
		:snapmirror_quiesce	=>	"snapmirror-quiesce",
		:snapmirror_release	=>	"snapmirror-release",
		:snapmirror_resume	=>	"snapmirror-resume",
		:snapmirror_resync	=>	"snapmirror-resync",
		:snapmirror_set_connection	=>	"snapmirror-set-connection",
		:snapmirror_set_schedule	=>	"snapmirror-set-schedule",
		:snapmirror_set_sync_schedule	=>	"snapmirror-set-sync-schedule",
		:snapmirror_throttle	=>	"snapmirror-throttle",
		:snapmirror_update	=>	"snapmirror-update",
		:snapshot_autodelete_list_info	=>	"snapshot-autodelete-list-info",
		:snapshot_autodelete_set_option	=>	"snapshot-autodelete-set-option",
		:snapshot_create	=>	"snapshot-create",
		:snapshot_delete	=>	"snapshot-delete",
		:snapshot_delta_info	=>	"snapshot-delta-info",
		:snapshot_get_reserve	=>	"snapshot-get-reserve",
		:snapshot_get_schedule	=>	"snapshot-get-schedule",
		:snapshot_list_info	=>	"snapshot-list-info",
		:snapshot_multicreate	=>	"snapshot-multicreate",
		:snapshot_multicreate_validate	=>	"snapshot-multicreate-validate",
		:snapshot_partial_restore_file	=>	"snapshot-partial-restore-file",
		:snapshot_partial_restore_file_list_info	=>	"snapshot-partial-restore-file-list-info",
		:snapshot_reclaimable_info	=>	"snapshot-reclaimable-info",
		:snapshot_rename	=>	"snapshot-rename",
		:snapshot_reserve_list_info	=>	"snapshot-reserve-list-info",
		:snapshot_restore_file	=>	"snapshot-restore-file",
		:snapshot_restore_file_info	=>	"snapshot-restore-file-info",
		:snapshot_restore_volume	=>	"snapshot-restore-volume",
		:snapshot_set_reserve	=>	"snapshot-set-reserve",
		:snapshot_set_schedule	=>	"snapshot-set-schedule",
		:snapshot_volume_info	=>	"snapshot-volume-info",
		:snapvault_add_softlock	=>	"snapvault-add-softlock",
		:snapvault_get_all_softlocked_snapshots	=>	"snapvault-get-all-softlocked-snapshots",
		:snapvault_get_softlocks	=>	"snapvault-get-softlocks",
		:snapvault_primary_abort_snapshot_create	=>	"snapvault-primary-abort-snapshot-create",
		:snapvault_primary_abort_transfer	=>	"snapvault-primary-abort-transfer",
		:snapvault_primary_delete_snapshot_schedule	=>	"snapvault-primary-delete-snapshot-schedule",
		:snapvault_primary_destinations_list_info	=>	"snapvault-primary-destinations-list-info",
		:snapvault_primary_get_relationship_status	=>	"snapvault-primary-get-relationship-status",
		:snapvault_primary_initiate_incremental_restore_transfer	=>	"snapvault-primary-initiate-incremental-restore-transfer",
		:snapvault_primary_initiate_restore_transfer	=>	"snapvault-primary-initiate-restore-transfer",
		:snapvault_primary_initiate_snapshot_create	=>	"snapvault-primary-initiate-snapshot-create",
		:snapvault_primary_relationship_status_list_iter_end	=>	"snapvault-primary-relationship-status-list-iter-end",
		:snapvault_primary_relationship_status_list_iter_next	=>	"snapvault-primary-relationship-status-list-iter-next",
		:snapvault_primary_relationship_status_list_iter_start	=>	"snapvault-primary-relationship-status-list-iter-start",
		:snapvault_primary_release_relationship	=>	"snapvault-primary-release-relationship",
		:snapvault_primary_set_snapshot_schedule	=>	"snapvault-primary-set-snapshot-schedule",
		:snapvault_primary_snapshot_schedule_list_info	=>	"snapvault-primary-snapshot-schedule-list-info",
		:snapvault_primary_snapshot_schedule_status_list_info	=>	"snapvault-primary-snapshot-schedule-status-list-info",
		:snapvault_remove_softlock	=>	"snapvault-remove-softlock",
		:snapvault_secondary_abort_snapshot_create	=>	"snapvault-secondary-abort-snapshot-create",
		:snapvault_secondary_abort_transfer	=>	"snapvault-secondary-abort-transfer",
		:snapvault_secondary_configuration_list_info	=>	"snapvault-secondary-configuration-list-info",
		:snapvault_secondary_create_relationship	=>	"snapvault-secondary-create-relationship",
		:snapvault_secondary_delete_relationship	=>	"snapvault-secondary-delete-relationship",
		:snapvault_secondary_delete_snapshot_schedule	=>	"snapvault-secondary-delete-snapshot-schedule",
		:snapvault_secondary_destinations_list_info	=>	"snapvault-secondary-destinations-list-info",
		:snapvault_secondary_get_configuration	=>	"snapvault-secondary-get-configuration",
		:snapvault_secondary_get_relationship_status	=>	"snapvault-secondary-get-relationship-status",
		:snapvault_secondary_initiate_incremental_transfer	=>	"snapvault-secondary-initiate-incremental-transfer",
		:snapvault_secondary_initiate_snapshot_create	=>	"snapvault-secondary-initiate-snapshot-create",
		:snapvault_secondary_modify_configuration	=>	"snapvault-secondary-modify-configuration",
		:snapvault_secondary_relationship_status_list_iter_end	=>	"snapvault-secondary-relationship-status-list-iter-end",
		:snapvault_secondary_relationship_status_list_iter_next	=>	"snapvault-secondary-relationship-status-list-iter-next",
		:snapvault_secondary_relationship_status_list_iter_start	=>	"snapvault-secondary-relationship-status-list-iter-start",
		:snapvault_secondary_release_relationship	=>	"snapvault-secondary-release-relationship",
		:snapvault_secondary_resync_relationship	=>	"snapvault-secondary-resync-relationship",
		:snapvault_secondary_set_snapshot_schedule	=>	"snapvault-secondary-set-snapshot-schedule",
		:snapvault_secondary_snapshot_schedule_list_info	=>	"snapvault-secondary-snapshot-schedule-list-info",
		:snapvault_secondary_snapshot_schedule_status_list_info	=>	"snapvault-secondary-snapshot-schedule-status-list-info",
		:snmp_community_add	=>	"snmp-community-add",
		:snmp_community_delete	=>	"snmp-community-delete",
		:snmp_community_delete_all	=>	"snmp-community-delete-all",
		:snmp_disable	=>	"snmp-disable",
		:snmp_enable	=>	"snmp-enable",
		:snmp_get	=>	"snmp-get",
		:snmp_get_next	=>	"snmp-get-next",
		:snmp_status	=>	"snmp-status",
		:snmp_trap_delete	=>	"snmp-trap-delete",
		:snmp_trap_disable	=>	"snmp-trap-disable",
		:snmp_trap_enable	=>	"snmp-trap-enable",
		:snmp_trap_list	=>	"snmp-trap-list",
		:snmp_trap_load	=>	"snmp-trap-load",
		:snmp_trap_reset	=>	"snmp-trap-reset",
		:snmp_trap_set	=>	"snmp-trap-set",
		:snmp_traphost_add	=>	"snmp-traphost-add",
		:snmp_traphost_delete	=>	"snmp-traphost-delete",
		:software_extract_metadata	=>	"software-extract-metadata",
		:storage_adapter_enable_adapter	=>	"storage-adapter-enable-adapter",
		:storage_adapter_get_adapter_info	=>	"storage-adapter-get-adapter-info",
		:storage_adapter_get_adapter_list	=>	"storage-adapter-get-adapter-list",
		:system_api_get_elements	=>	"system-api-get-elements",
		:system_api_list	=>	"system-api-list",
		:system_api_list_types	=>	"system-api-list-types",
		:system_available_replication_transfers	=>	"system-available-replication-transfers",
		:system_get_info	=>	"system-get-info",
		:system_get_ontapi_version	=>	"system-get-ontapi-version",
		:system_get_vendor_info	=>	"system-get-vendor-info",
		:system_get_version	=>	"system-get-version",
		:useradmin_domainuser_add	=>	"useradmin-domainuser-add",
		:useradmin_domainuser_delete	=>	"useradmin-domainuser-delete",
		:useradmin_domainuser_list	=>	"useradmin-domainuser-list",
		:useradmin_group_add	=>	"useradmin-group-add",
		:useradmin_group_delete	=>	"useradmin-group-delete",
		:useradmin_group_list	=>	"useradmin-group-list",
		:useradmin_group_modify	=>	"useradmin-group-modify",
		:useradmin_role_add	=>	"useradmin-role-add",
		:useradmin_role_delete	=>	"useradmin-role-delete",
		:useradmin_role_list	=>	"useradmin-role-list",
		:useradmin_role_modify	=>	"useradmin-role-modify",
		:useradmin_user_add	=>	"useradmin-user-add",
		:useradmin_user_delete	=>	"useradmin-user-delete",
		:useradmin_user_list	=>	"useradmin-user-list",
		:useradmin_user_modify	=>	"useradmin-user-modify",
		:useradmin_user_modify_password	=>	"useradmin-user-modify-password",
		:vfiler_add_ipaddress	=>	"vfiler-add-ipaddress",
		:vfiler_add_storage	=>	"vfiler-add-storage",
		:vfiler_allow_protocol	=>	"vfiler-allow-protocol",
		:vfiler_create	=>	"vfiler-create",
		:vfiler_destroy	=>	"vfiler-destroy",
		:vfiler_disallow_protocol	=>	"vfiler-disallow-protocol",
		:vfiler_dr_activate	=>	"vfiler-dr-activate",
		:vfiler_dr_configure	=>	"vfiler-dr-configure",
		:vfiler_dr_delete	=>	"vfiler-dr-delete",
		:vfiler_dr_get_status	=>	"vfiler-dr-get-status",
		:vfiler_dr_resync	=>	"vfiler-dr-resync",
		:vfiler_get_allowed_protocols	=>	"vfiler-get-allowed-protocols",
		:vfiler_get_disallowed_protocols	=>	"vfiler-get-disallowed-protocols",
		:vfiler_get_status	=>	"vfiler-get-status",
		:vfiler_list_info	=>	"vfiler-list-info",
		:vfiler_migrate	=>	"vfiler-migrate",
		:vfiler_migrate_cancel	=>	"vfiler-migrate-cancel",
		:vfiler_migrate_complete	=>	"vfiler-migrate-complete",
		:vfiler_migrate_start	=>	"vfiler-migrate-start",
		:vfiler_migrate_status	=>	"vfiler-migrate-status",
		:vfiler_remove_ipaddress	=>	"vfiler-remove-ipaddress",
		:vfiler_remove_storage	=>	"vfiler-remove-storage",
		:vfiler_setup	=>	"vfiler-setup",
		:vfiler_start	=>	"vfiler-start",
		:vfiler_stop	=>	"vfiler-stop",
		:volume_add	=>	"volume-add",
		:volume_autosize_get	=>	"volume-autosize-get",
		:volume_autosize_set	=>	"volume-autosize-set",
		:volume_charmap_get	=>	"volume-charmap-get",
		:volume_charmap_set	=>	"volume-charmap-set",
		:volume_clone_create	=>	"volume-clone-create",
		:volume_clone_split_estimate	=>	"volume-clone-split-estimate",
		:volume_clone_split_start	=>	"volume-clone-split-start",
		:volume_clone_split_status	=>	"volume-clone-split-status",
		:volume_clone_split_stop	=>	"volume-clone-split-stop",
		:volume_container	=>	"volume-container",
		:volume_create	=>	"volume-create",
		:volume_decompress_abort	=>	"volume-decompress-abort",
		:volume_decompress_start	=>	"volume-decompress-start",
		:volume_destroy	=>	"volume-destroy",
		:volume_get_filer_info	=>	"volume-get-filer-info",
		:volume_get_language	=>	"volume-get-language",
		:volume_get_root_name	=>	"volume-get-root-name",
		:volume_get_supported_guarantees	=>	"volume-get-supported-guarantees",
		:volume_list_info	=>	"volume-list-info",
		:volume_list_info_iter_end	=>	"volume-list-info-iter-end",
		:volume_list_info_iter_next	=>	"volume-list-info-iter-next",
		:volume_list_info_iter_start	=>	"volume-list-info-iter-start",
		:volume_mediascrub_list_info	=>	"volume-mediascrub-list-info",
		:volume_mirror	=>	"volume-mirror",
		:volume_offline	=>	"volume-offline",
		:volume_online	=>	"volume-online",
		:volume_options_list_info	=>	"volume-options-list-info",
		:volume_rename	=>	"volume-rename",
		:volume_restrict	=>	"volume-restrict",
		:volume_scrub_list_info	=>	"volume-scrub-list-info",
		:volume_scrub_resume	=>	"volume-scrub-resume",
		:volume_scrub_start	=>	"volume-scrub-start",
		:volume_scrub_stop	=>	"volume-scrub-stop",
		:volume_scrub_suspend	=>	"volume-scrub-suspend",
		:volume_set_language	=>	"volume-set-language",
		:volume_set_option	=>	"volume-set-option",
		:volume_set_total_files	=>	"volume-set-total-files",
		:volume_size	=>	"volume-size",
		:volume_split	=>	"volume-split",
		:volume_verify_list_info	=>	"volume-verify-list-info",
		:volume_verify_resume	=>	"volume-verify-resume",
		:volume_verify_start	=>	"volume-verify-start",
		:volume_verify_stop	=>	"volume-verify-stop",
		:volume_verify_suspend	=>	"volume-verify-suspend",
		:volume_wafl_info	=>	"volume-wafl-info",
		:wafl_sync	=>	"wafl-sync",
	}

	def map_method(msym)
		return MehodMap[msym]
	end

end # module OntapMethodMap
