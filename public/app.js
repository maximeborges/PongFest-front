'use strict';

angular.module('LaserPong', [
    'ui.router',
    'facebook'
])
.config(['$stateProvider', '$urlRouterProvider', 'FacebookProvider',
    function($stateProvider, $urlRouterProvider, FacebookProvider) {
        FacebookProvider.init(window.FACEBOOK_APP_ID + "");

        $urlRouterProvider.otherwise("/start");
        $stateProvider
            .state('start', {
                url: '/start',
                templateUrl: 'start.html',
                controller: 'startCtrl'
            })
            .state('select', {
                url: '/select',
                templateUrl: 'select.html',
                controller: 'selectCtrl'
            })
            .state('game', {
                url: '/game',
                templateUrl: 'game.html',
                controller: 'gameCtrl'
            })
            .state('subscribe', {
                url: '/subscribe',
                templateUrl: 'subscribe.html',
                controller: 'subscribeCtrl'
            })
    }
])
.controller('startCtrl', ['$scope', '$timeout', 'Facebook', '$http', '$state',
function($scope, $timeout, Facebook, $http, $state) {
    $scope.pseudoToggle = false;
    $scope.user = {};

    $scope.logged = false;

    Facebook.getLoginStatus(function(response) {
        if (response.status == 'connected') {
            $scope.logged = true;
        }
    });

    /**
     * Login
     */
    $scope.login = function() {
        if(!$scope.logged)
            Facebook.login(function(response) {
                if (response.status == 'connected') {
                    $scope.logged = true;
                    $scope.me();
                }
            });
    };

    /**
     * Get current user infos
     */
    $scope.me = function(callback) {
        Facebook.api('/me', function(response) {
            $scope.$apply(function() {
                $scope.user = response;
            });
            if(typeof callback == 'function')
                callback(response);

        });
    };

    /**
     * Logout
     */
    /*$scope.logout = function() {
        if($scope.logged)
            Facebook.logout(function() {
                $scope.$apply(function() {
                    $scope.user   = {};
                    $scope.logged = false;
                });
            });
    };*/



    /**
     * Connect
     */
    $scope.connect = function(user) {
        var infos = {};
        if(typeof user === "object")
            infos = {
                id: user.id,
                firstName: user.first_name,
                lastName: user.last_name
            };
        else infos = {name: pseudo};

        $http.post('/api/users', infos
        ).success(function(resp) {
            $state.go('select');
            console.log(resp)
        }).error(function(err) {
            console.log(err)
        })
    };

    /**
     * Events
     */
    $scope.$on('Facebook:statusChange', function(ev, data) {
        console.log("Status: ", data);
        if (data.status == 'connected') {
            // Get current user
            $scope.me(function(user) {
                $scope.connect(user);
            });
        }
    });
}])
.controller('selectCtrl', ['$scope', '$timeout', 'Facebook', '$http', '$state',
function($scope, $timeout, Facebook, $http, $state) {

}])
.controller('subscribeCtrl', ['$scope', function($scope) {
    //$scope
}])
.run(['$window', '$rootScope', '$state', function($window, $rootScope, $state) {
    $rootScope.$state = $state;
}]);


