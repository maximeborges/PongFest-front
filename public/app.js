'use strict';

angular.module('LaserPong', [
    'ui.router',
    'facebook',
    'mailchimp',
    'ngWebsocket',
    'chart.js'
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
        .state('leaderboard', {
            url: '/leaderboard',
            templateUrl: 'leaderboard.html',
            controller: 'leaderBoardCtrl'
        })
}])
.controller('startCtrl', ['$rootScope', '$scope', '$timeout', 'Facebook', '$http', '$state',
function($rootScope, $scope, $timeout, Facebook, $http, $state) {
    $scope.pseudoToggle = false;
    $scope.map = false;
    $scope.here = false;

    /**
     * Display the map 
     */
    $scope.displayMap = function() {
        $scope.map = true;
        // have to redisplay the map because it was hidden
        angular.element(document.getElementById('embedded_map')).attr('src', angular.element(document.getElementById('embedded_map')).attr('src'));
    };
    
    /**
     * Display the connection options
     */
    $scope.imHere = function() {
        $scope.here = true;
    };

    /**
     * Send user infos to the server
     */
    $scope.connect = function(user) {
        var infos = {};
        if(typeof user === "object")
            infos = {
                id: user.id,
                firstName: user.first_name,
                lastName: user.last_name
            };
        else {
            infos = {name: user};
        }

        $http.post('/api/users', infos
        ).success(function(resp) {
            $rootScope.user = {
                id: resp._id,
                token: resp.token,
                name: resp.name,
                role: resp.role
            };
            $state.go('game');
        }).error(function(err) {
            console.log(err)
        })
    };
}])
.controller('leaderBoardCtrl', ['$rootScope', '$scope', function($rootScope, $scope) {
    $scope.doughnutData = [120, 80];
    $scope.doughnutLabels = ['Droite', 'Gauche'];
    $scope.doughnutColours = ['#CC1700', '#41CC00'];
}])
.controller('gameCtrl', ['$rootScope', '$scope', function($rootScope, $scope) {
    $scope.sendInput = function(dir) {
        $rootScope.ws.$emit('message', {
            "type": "input",
            "token": $rootScope.user.token,
            "input": dir
        })
    };
}])
.run(['$rootScope', '$state', 'Facebook', '$window', '$websocket', function($rootScope, $state, Facebook, $window, $websocket) {
    //debug
    $rootScope.$state = $state;

    // WEBSOCKET
    $rootScope.ws = $rootScope.ws = $websocket.$new("ws://"+$window.location.host+"/ws");
    $rootScope.gameStatus = {
        left: {
            score: 0,
            players: 0
        },
        right: {
            score: 0,
            players: 0
        }};
    $rootScope.ws.$on('score', function(data) {
        $rootScope.gameStatus.left = data.left;
        $rootScope.gameStatus.right = data.right;
        $scope.$apply();
    });

    $rootScope.ws.$on('ping', function(data) {
        console.log("websocket ping - " + new Date(data.ts))
    });

    // User
    $rootScope.user = null;

    $rootScope.logged = false;

    $rootScope.FB = {
        login: function() {
            if(!$rootScope.logged)
                Facebook.login(function(user) {
                    if(user.status == "connected") {
                        $rootScope.logged = true;
                        $rootScope.FB.me();
                    }
                }, {scope: 'email'});
        },
        logout: function() {
            $rootScope.user = null;
            $rootScope.logged = false;
        },
        me: function() {
            Facebook.api('/me', function(response) {
                $rootScope.$apply(function() {
                    $rootScope.user = response;
                });
            });
        }
    };

    // Events
    $rootScope.$on('Facebook:statusChange', function(ev, data) {
        if (data.status == 'connected') {
        }
        if (data.status == 'unknown') {
            $rootScope.logged = false;
        }
    });

    // States
    $rootScope.$on('$stateChangeStart', function(e, toState, toParams, fromState, fromParams) {
        if(!$rootScope.user && toState.name != 'start' && toState.name != 'subscribe') {
            e.preventDefault();
            $state.go('start');
        }
    });
}]);
