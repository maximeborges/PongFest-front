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
        var infos;
        if(typeof user === "object")
            infos = {
                id: user.id,
                firstName: user.first_name,
                lastName: user.last_name
            };
        else {
            infos = {name: user};
        }
        $rootScope.ws.$emit('createUser', infos);
    };
}])
.controller('leaderBoardCtrl', ['$rootScope', '$scope', '$http', function($rootScope, $scope, $http) {
    //$scope.doughnutData = [120, 80];
    //$scope.doughnutLabels = ['', ''];
    //$scope.doughnutColours = ['#CC1700', '#41CC00'];
    //$scope.goodPlayers = [];
    //$scope.badPlayers = [];
    $scope.notifications = [];
    $http.get('api/top100').
    success(function(data, status, headers, config) {
        $scope.top100 = data;
    });
    $http.get('api/flop100').
    success(function(data, status, headers, config) {
        $scope.flop100 = data;
    });
}])
.controller('subscribeCtrl', [function() {

}])
.controller('gameCtrl', ['$rootScope', '$scope', function($rootScope, $scope) {
    $scope.sendInput = function(dir) {
        $rootScope.ws.$emit('input', {
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
        },
        totalPlayers: 0
    };

    $rootScope.ws.$on('user', function(data) {
        if(data._id) {
            $rootScope.user = {
                id: data._id,
                token: data.token,
                name: data.name,
                role: data.role
            };
            $state.go('game');
        }
        else console.log(data)
    });
    $rootScope.ws.$on('players', function(data) {
        console.log(data);
        $rootScope.gameStatus.left.players = data.left|0;
        $rootScope.gameStatus.right.players = data.right|0;
        $rootScope.gameStatus.totalPlayers = data.total|0;
        $rootScope.$apply();
    });
    $rootScope.ws.$on('score', function(data) {
        $rootScope.gameStatus.left.score = data.left|0;
        $rootScope.gameStatus.right.score = data.right|0;
        $rootScope.$apply();
    });
    $rootScope.ws.$on('notification', function(data) {
        $scope.notifications.push({"name": data.user.name, "role": data.user.role, "score": data.type});
        console.log("received notification " + data.type)
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
        if(!$rootScope.user && toState.name != 'start' && toState.name != 'subscribe' && toState.name != "leaderboard") {
            e.preventDefault();
            $state.go('start');
        }
    });
}]);
