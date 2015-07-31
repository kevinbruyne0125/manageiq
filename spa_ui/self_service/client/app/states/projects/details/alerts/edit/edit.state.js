(function() {
  'use strict';

  angular.module('app.states')
    .run(appRun);

  /** @ngInject */
  function appRun(routerHelper, navigationHelper) {
    routerHelper.configureStates(getStates());
    navigationHelper.navItems(navItems());
    navigationHelper.sidebarItems(sidebarItems());
  }

  function getStates() {
    return {
      'projects.alerts.edit': {
        url: '/edit/:id',
        templateUrl: 'app/states/projects/details/alerts/edit/edit.html',
        controller: StateController,
        controllerAs: 'vm',
        title: 'Project Alerts Edit',
        resolve: {
          alertRecord: resolveAlert,
          staff: resolveStaff
        }
      }
    };
  }

  function navItems() {
    return {};
  }

  function sidebarItems() {
    return {};
  }

  /** @ngInject */
  function resolveAlert($stateParams, Alert) {
    if ($stateParams.id) {
      return Alert.get({id: $stateParams.id}).$promise;
    } else {
      return {};
    }
  }

  /** @ngInject */
  function resolveStaff(Staff) {
    return Staff.getCurrentMember().$promise;
  }

  /** @ngInject */
  function StateController(logger, alertRecord, $stateParams, staff) {
    var vm = this;

    vm.title = 'Project Alerts Edit';
    vm.alertRecord = alertRecord;
    vm.activate = activate;
    vm.staffId = staff.id;
    vm.home = 'projects.details';
    vm.homeParams = { projectId: $stateParams.projectId };

    // HARD CODED FOR SINGLE TENANT
    vm.alertableType = 'Project';
    vm.alertableId = $stateParams.projectId;

    activate();

    function activate() {
      logger.info('Activated Project Alerts Edit View');
    }
  }
})();
