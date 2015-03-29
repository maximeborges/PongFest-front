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
}])
.controller('startCtrl', ['$rootScope', '$scope', '$timeout', 'Facebook', '$http', '$state',
function($rootScope, $scope, $timeout, Facebook, $http, $state) {
    $scope.pseudoToggle = false;
    
    /**
     * Display the map 
     */
    $scope.displayMap = function() {
        $rootScope.map = true;
    };
    
    /**
     * Display the connection options
     */
    $scope.imHere = function() {
        $rootScope.here = true;
    };

    /**
     * Send user infos to the server
     */
    $scope.connect = function(user) {
        var infos = {};
        if(typeof user === "object")
            infos = {
                id: user.id,
                name: user.first_name + ' ' + user.last_name
            };
        else {
            infos = {name: user};
        }

        $http.post('/api/users', infos
        ).success(function(resp) {
            $rootScope.user = {
                id: resp._id,
                token: resp.token,
                name: resp.name
            };
            $state.go('select');
        }).error(function(err) {
            console.log(err)
        })
    };
}])
.controller('selectCtrl', ['$rootScope', '$scope', '$timeout', 'Facebook', '$http', '$state',
function($rootScope, $scope, $timeout, Facebook, $http, $state) {

    $scope.select = function(role) {
        $http.patch('/api/users/' + $rootScope.user.token, {role: role})
            .success(function(resp) {
                $rootScope.user.role = resp.role;
                $state.go('game');
            })
            .error(function(resp) {
                $state.go('start');
            });
    };

    $scope.disconnect = function() {
        Facebook.getLoginStatus(function(response) {
            if(response.status === 'connected') {
                FB.logout();
            } else {
                $rootScope.user = null;
                $rootScope.logged = false;
            }
            $state.go('start');
        });
    };
}])
.controller('subscribeCtrl', ['$rootScope', '$scope', function($rootScope, $scope) {
    //$scope
}])
.controller('gameCtrl', ['$rootScope', '$scope', function($rootScope, $scope) {

}])
.run(['$window', '$rootScope', '$state', 'Facebook', function($window, $rootScope, $state, Facebook) {
    $rootScope.user = null;

    $rootScope.logged = false;
    $rootScope.map = false;
    $rootScope.here = false;

    $rootScope.FB = {
        login: function() {
            if(!$rootScope.logged)
                Facebook.login();
        },
        logout: function() {
            if($rootScope.logged)
                Facebook.logout(function() {
                    $rootScope.$apply(function() {
                        $rootScope.user = null;
                        $rootScope.logged = false;
                    });
                });
        },
        me: function() {
            Facebook.api('/me', function(response) {
                $rootScope.$apply(function() {
                    $rootScope.user = response;
                });
            });
        }
    };

    /**
     * Events
     */
    $rootScope.$on('Facebook:statusChange', function(ev, data) {
        if (data.status == 'connected') {
            $rootScope.logged = true;
            $rootScope.FB.me();
        }
        if (data.status == 'unknown') {
            $rootScope.logged = false;
        }
    });

    // States
    $rootScope.$on('$stateChangeStart', function(e, toState, toParams, fromState, fromParams) {
        if(!$rootScope.user && toState.name != 'start') {
            e.preventDefault();
            $state.go('start');
        }
    });
}]);
