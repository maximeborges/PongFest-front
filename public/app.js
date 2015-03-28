'use strict';

angular.module('LaserPong', [
    'ui.router',
    'facebook'
])
.config(['$stateProvider', '$urlRouterProvider', 'FacebookProvider',
    function($stateProvider, $urlRouterProvider, FacebookProvider) {

    FacebookProvider.init('893554934040564');

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
}])
.controller('startCtrl', ['$scope', '$timeout', 'Facebook', '$http', function($scope, $timeout, Facebook, $http) {
    $scope.user = {};

    $scope.logged = false;

    $scope.$watch(
        function() {
            return Facebook.isReady();
        },
        function(newVal) {
            if (newVal)
                $scope.facebookReady = true;
        }
    );

    var userIsConnected = false;

    Facebook.getLoginStatus(function(response) {
        if (response.status == 'connected') {
            userIsConnected = true;
        }
    });

    /**
     * IntentLogin
     */
    $scope.IntentLogin = function() {
        if(!userIsConnected) {
            $scope.login();
        }
    };

    /**
     * Login
     */
    $scope.login = function() {
        Facebook.login(function(response) {
            if (response.status == 'connected') {
                $scope.logged = true;
                $scope.me();
            }

        });
    };

    /**
     * me
     */
    $scope.me = function() {
        Facebook.api('/me', function(response) {
            /**
             * Using $scope.$apply since this happens outside angular framework.
             */
            $scope.$apply(function() {
                $scope.user = response;
            });

        });
    };

    /**
     * Logout
     */
    $scope.logout = function() {
        Facebook.logout(function() {
            $scope.$apply(function() {
                $scope.user   = {};
                $scope.logged = false;
            });
        });
    };

    /**
     * Taking approach of Events :D
     */
    $scope.$on('Facebook:statusChange', function(ev, data) {
        console.log('Status: ', data);
        if (data.status == 'connected') {
            $scope.$apply(function() {
                $http.post('/api/users', {
                        id: $scope.user.id,
                        firstName: $scope.user.first_name,
                        lastName: $scope.user.last_name
                    }, function(resp) {
                        console.log(resp)
                    })
            });
        } else {
            $scope.$apply(function() {

            });
        }


    });
}])
.controller('subscribeCtrl', ['$scope', function($scope) {
    //$scope
}])
.run(['$window', '$rootScope', '$state', function($window, $rootScope, $state) {
    $rootScope.$state = $state;
}]);


