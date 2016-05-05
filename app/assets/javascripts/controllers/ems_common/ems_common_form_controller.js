ManageIQ.angular.app.controller('emsCommonFormController', ['$http', '$scope', '$attrs', 'emsCommonFormId', 'miqService', function($http, $scope, $attrs, emsCommonFormId, miqService) {
  var init = function() {
    $scope.emsCommonModel = {
      name: '',
      emstype: '',
      openstack_infra_providers_exist: false,
      provider_id: '',
      zone: '',
      hostname: '',
      default_hostname: '',
      amqp_hostname: '',
      hawkular_hostname: '',
      metrics_hostname: '',
      project: '',
      default_api_port: '',
      amqp_api_port: '',
      hawkular_api_port: '',
      metrics_port: '',
      api_version: '',
      default_security_protocol: '',
      realm: '',
      security_protocol: '',
      amqp_security_protocol: '',
      provider_region: '',
      default_userid: '',
      default_password: '',
      default_verify: '',
      amqp_userid: '',
      amqp_password: '',
      amqp_verify: '',
      metrics_userid: '',
      metrics_password: '',
      metrics_verify: '',
      ssh_keypair_userid: '',
      ssh_keypair_password: '',
      service_account: '',
      emstype_vm: false,
      ems_common: true,
      azure_tenant_id: '',
      keystone_v3_domain_id: '',
      subscription: '',
      host_default_vnc_port_start: '',
      host_default_vnc_port_end: '',
      event_stream_selection: '',
      ems_controller: ''
    };
    $scope.realmNote = __("Note: Username must be in the format: name@realm");
    $scope.formId = emsCommonFormId;
    $scope.afterGet = false;
    $scope.validateClicked = miqService.validateWithREST;
    $scope.modelCopy = angular.copy( $scope.emsCommonModel );
    $scope.formFieldsUrl = $attrs.formFieldsUrl;
    $scope.createUrl = $attrs.createUrl;
    $scope.updateUrl = $attrs.updateUrl;
    $scope.model = 'emsCommonModel';

    ManageIQ.angular.scope = $scope;

    if (emsCommonFormId == 'new') {
      $scope.newRecord                  = true;

      miqService.sparkleOn();
      $http.get($scope.formFieldsUrl + emsCommonFormId).success(function(data) {
        $scope.emsCommonModel.zone                            = data.zone;
        $scope.emsCommonModel.emstype_vm                      = data.emstype_vm;
        $scope.emsCommonModel.openstack_infra_providers_exist = data.openstack_infra_providers_exist;
        $scope.emsCommonModel.default_api_port                = 5000;
        $scope.emsCommonModel.amqp_api_port                   = 5672;
        $scope.emsCommonModel.hawkular_api_port               = 443;
        $scope.emsCommonModel.api_version                     = 'v2';
        $scope.emsCommonModel.ems_controller                  = data.ems_controller;
        miqService.sparkleOff();
      });
      $scope.afterGet  = true;
      $scope.modelCopy = angular.copy( $scope.emsCommonModel );
    }
    else {
      $scope.newRecord = false;
      miqService.sparkleOn();

      $http.get($scope.formFieldsUrl + emsCommonFormId).success(function(data) {
        $scope.emsCommonModel.name                            = data.name;
        $scope.emsCommonModel.emstype                         = data.emstype;
        $scope.emsCommonModel.zone                            = data.zone;
        $scope.emsCommonModel.hostname                        = data.hostname;
        $scope.emsCommonModel.default_hostname                = data.default_hostname;
        $scope.emsCommonModel.amqp_hostname                   = data.amqp_hostname;
        $scope.emsCommonModel.hawkular_hostname               = data.hawkular_hostname;
        $scope.emsCommonModel.metrics_hostname                = data.metrics_hostname;
        $scope.emsCommonModel.project                         = data.project;

        $scope.emsCommonModel.openstack_infra_providers_exist = data.openstack_infra_providers_exist;

        $scope.emsCommonModel.provider_id                     = angular.isDefined(data.provider_id) ? data.provider_id.toString() : "";

        $scope.emsCommonModel.default_api_port                = angular.isDefined(data.default_api_port) && data.default_api_port != '' ? data.default_api_port : '5000';
        $scope.emsCommonModel.amqp_api_port                   = angular.isDefined(data.amqp_api_port) && data.amqp_api_port != '' ? data.amqp_api_port : '5672';
        $scope.emsCommonModel.hawkular_api_port               = angular.isDefined(data.hawkular_api_port) && data.hawkular_api_port != '' ? data.default_api_port : '8443';
        $scope.emsCommonModel.metrics_api_port                = angular.isDefined(data.metrics_api_port) && data.metrics_api_port != '' ? data.metrics_api_port : '';
        $scope.emsCommonModel.api_version                     = data.api_version;
        $scope.emsCommonModel.default_security_protocol       = data.default_security_protocol;
        $scope.emsCommonModel.realm                           = data.realm;
        $scope.emsCommonModel.security_protocol               = data.security_protocol;
        $scope.emsCommonModel.amqp_security_protocol          = data.amqp_security_protocol != '' ? data.amqp_security_protocol : 'non-ssl';
        $scope.emsCommonModel.provider_region                 = data.provider_region;
        $scope.emsCommonModel.default_userid                  = data.default_userid;
        $scope.emsCommonModel.amqp_userid                     = data.amqp_userid;
        $scope.emsCommonModel.metrics_userid                  = data.metrics_userid;

        $scope.emsCommonModel.ssh_keypair_userid              = data.ssh_keypair_userid;

        $scope.emsCommonModel.service_account                 = data.service_account;
        $scope.emsCommonModel.azure_tenant_id                 = data.azure_tenant_id;
        $scope.emsCommonModel.keystone_v3_domain_id           = data.keystone_v3_domain_id;
        $scope.emsCommonModel.subscription                    = data.subscription;

        $scope.emsCommonModel.host_default_vnc_port_start     = data.host_default_vnc_port_start;
        $scope.emsCommonModel.host_default_vnc_port_end       = data.host_default_vnc_port_end;

        $scope.emsCommonModel.event_stream_selection          = data.event_stream_selection;

        $scope.emsCommonModel.ems_controller                  = data.ems_controller;

        if($scope.emsCommonModel.default_userid != '') {
          $scope.emsCommonModel.default_password = $scope.emsCommonModel.default_verify = miqService.storedPasswordPlaceholder;
        }
        if($scope.emsCommonModel.amqp_userid != '') {
          $scope.emsCommonModel.amqp_password = $scope.emsCommonModel.amqp_verify = miqService.storedPasswordPlaceholder;
        }
        if($scope.emsCommonModel.metrics_userid != '') {
          $scope.emsCommonModel.metrics_password = $scope.emsCommonModel.metrics_verify = miqService.storedPasswordPlaceholder;
        }
        if($scope.emsCommonModel.ssh_keypair_userid != '') {
          $scope.emsCommonModel.ssh_keypair_password = miqService.storedPasswordPlaceholder;
        }

        $scope.afterGet  = true;
        $scope.modelCopy = angular.copy( $scope.emsCommonModel );

        miqService.sparkleOff();
      });
    }
    $scope.currentTab = "default";
  };

  $scope.changeAuthTab = function(id) {
    $scope.currentTab = id;
  }

  $scope.canValidateBasicInfo = function () {
    return $scope.isBasicInfoValid()
  }

  $scope.isBasicInfoValid = function() {
    if(($scope.currentTab == "default" && $scope.emsCommonModel.emstype != "azure") &&
      ($scope.emsCommonModel.emstype == "ec2" ||
      ($scope.emsCommonModel.emstype == "openstack" && $scope.emsCommonModel.default_hostname ||
       $scope.emsCommonModel.emstype == "scvmm" && $scope.emsCommonModel.default_hostname ||
       $scope.emsCommonModel.emstype == "openstack_infra" && $scope.emsCommonModel.default_hostname ||
       $scope.emsCommonModel.emstype == "rhevm" && $scope.emsCommonModel.default_hostname ||
       $scope.emsCommonModel.emstype == "vmwarews" && $scope.emsCommonModel.default_hostname)) &&
      ($scope.emsCommonModel.default_userid != '' && $scope.angularForm.default_userid.$valid &&
       $scope.emsCommonModel.default_password != '' && $scope.angularForm.default_password.$valid &&
       $scope.emsCommonModel.default_verify != '' && $scope.angularForm.default_verify.$valid)) {
      return true;
    } else if(($scope.currentTab == "amqp") &&
      ($scope.emsCommonModel.amqp_hostname) &&
      ($scope.emsCommonModel.amqp_userid != '' && $scope.angularForm.amqp_userid.$valid &&
       $scope.emsCommonModel.amqp_password != '' && $scope.angularForm.amqp_password.$valid &&
       $scope.emsCommonModel.amqp_verify != '' && $scope.angularForm.amqp_verify.$valid)) {
      return true;
    } else if(($scope.currentTab == "default" && $scope.emsCommonModel.emstype == "azure") &&
      ($scope.emsCommonModel.azure_tenant_id != '' && $scope.angularForm.azure_tenant_id.$valid) &&
      ($scope.emsCommonModel.default_userid != '' && $scope.angularForm.default_userid.$valid &&
       $scope.emsCommonModel.default_password != '' && $scope.angularForm.default_password.$valid &&
       $scope.emsCommonModel.default_verify != '' && $scope.angularForm.default_verify.$valid)) {
      return true;
    } else if(($scope.currentTab == "ssh_keypair" && $scope.emsCommonModel.emstype == "openstack_infra") &&
      ($scope.emsCommonModel.ssh_keypair_userid != '' && $scope.angularForm.ssh_keypair_userid.$valid &&
      $scope.emsCommonModel.ssh_keypair_password != '' && $scope.angularForm.ssh_keypair_password.$valid)) {
      return true;
    } else if(($scope.currentTab == "metrics" && $scope.emsCommonModel.emstype == "rhevm") &&
      ($scope.emsCommonModel.metrics_hostname != '' && $scope.angularForm.metrics_hostname.$valid && $scope.emsCommonModel.metrics_api_port != '') &&
      ($scope.emsCommonModel.metrics_userid != '' && $scope.angularForm.metrics_userid.$valid &&
      $scope.emsCommonModel.metrics_password != '' && $scope.angularForm.metrics_password.$valid &&
      $scope.emsCommonModel.metrics_verify != '' && $scope.angularForm.metrics_verify.$valid)) {
      return true;
    } else if(($scope.currentTab == "hawkular") &&
      ($scope.angularForm.hawkular_hostname.$valid && $scope.emsCommonModel.hawkular_api_port != '')) {
      return true;
    } else if($scope.emsCommonModel.emstype == "gce" && $scope.emsCommonModel.project != '' &&
      ($scope.currentTab == "default" ||
      ($scope.currentTab == "service_account" && $scope.emsCommonModel.service_account != ''))) {
      return true;
    }

    else
      return false;
  };

  var emsCommonEditButtonClicked = function(buttonName, serializeFields, $event) {
    miqService.sparkleOn();
    var url = $scope.updateUrl + '?button=' + buttonName;
    miqService.restAjaxButton(url, $event.target);
  };

  var emsCommonAddButtonClicked = function(buttonName, serializeFields, $event) {
    miqService.sparkleOn();
    var url = $scope.createUrl + '?button=' + buttonName;
    miqService.restAjaxButton(url, $event.target);
  };

  $scope.cancelClicked = function($event) {
    angular.element('#button_name').val('cancel');
    if($scope.newRecord)
      emsCommonAddButtonClicked('cancel', false, $event);
    else
      emsCommonEditButtonClicked('cancel', false, $event);

    $scope.angularForm.$setPristine(true);
  };

  $scope.resetClicked = function() {
    $scope.$broadcast ('resetClicked');
    $scope.emsCommonModel = angular.copy( $scope.modelCopy );
    $scope.angularForm.$setPristine(true);
    miqService.miqFlash("warn", __("All changes have been reset"));
  };

  $scope.saveClicked = function($event, formSubmit) {
    if(formSubmit) {
      angular.element('#button_name').val('save');
      emsCommonEditButtonClicked('save', true, $event);
      $scope.angularForm.$setPristine(true);
    }
    else {
      $event.preventDefault();
    }
  };

  $scope.addClicked = function($event, formSubmit) {
    if(formSubmit) {
      angular.element('#button_name').val('add');
      emsCommonAddButtonClicked('add', true, $event);
      $scope.angularForm.$setPristine(true);
    }
    else {
      $event.preventDefault();
    }
  };

  $scope.isRegionSupported = function() {
    if ($scope.emsCommonModel.emstype === 'ec2' || $scope.emsCommonModel.emstype === 'azure') {
      return true;
    }

    return false;
  };

  $scope.providerTypeChanged = function() {
    $scope.emsCommonModel.default_api_port = "";
    $scope.emsCommonModel.default_security_protocol = "";
    $scope.note = "";
    if ($scope.emsCommonModel.emstype === 'openstack' || $scope.emsCommonModel.emstype === 'openstack_infra') {
      $scope.emsCommonModel.default_api_port = "5000";
      $scope.emsCommonModel.event_stream_selection = "ceilometer";
      $scope.emsCommonModel.amqp_security_protocol = 'non-ssl';
    } else if ($scope.emsCommonModel.emstype === 'scvmm' && $scope.emsCommonModel.default_security_protocol === 'kerberos'){
      $scope.note = $scope.realmNote;
    } else if ($scope.emsCommonModel.emstype === 'rhevm'){
      $scope.emsCommonModel.metrics_api_port = "5432";
    } else if ($scope.emsCommonModel.emstype === 'openshift' || $scope.emsCommonModel.emstype === 'openshift_enterprise'){
      $scope.emsCommonModel.default_api_port = "8443";
    } else if ($scope.emsCommonModel.emstype === 'atomic' || $scope.emsCommonModel.emstype === 'atomic_enterprise'){
      $scope.emsCommonModel.default_api_port = "8443";
    } else if ($scope.emsCommonModel.emstype === 'kubernetes'){
      $scope.emsCommonModel.default_api_port = "8443";
    }
  };

  $scope.scvmmSecurityProtocolChanged = function() {
    $scope.note = "";
    if ($scope.emsCommonModel.emstype === 'scvmm' && $scope.emsCommonModel.default_security_protocol === 'kerberos'){
      $scope.note = $scope.realmNote;
    }
  };

  init();
}]);
