ManageIQ.angular.app.factory('arbitrationProfileDataFactory', ['$http', function($http) {
  var factoryService = {
    getArbitrationProfileData: function(ems_id, id) {
      alert("in app/assets/javascripts/factories/ems_cloud/arbitration_profile_data.js")
      if(angular.isDefined(id)) {
        var promise = $http({
          method: 'GET',
          url: '/ems_cloud/arbitration_profile_form_fields/' + id
        }).success(function (data, status, headers, config) {
          return data;
        });
        return promise;
      }
    }
  }
  return factoryService;
}]);

