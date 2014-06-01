/**
 * @ngdoc module
 * @name ngRouteForMultiView
 * @description
 *
*/


(function() {
  var $Route4MultiViewProvider, DEFAULT_VIEW_KEY, OTHERWISE_PATH, ngMultiViewFactory, ngMultiViewFillContentFactory, ngRoute4MultiViewModule,
    __slice = [].slice;

  ngRoute4MultiViewModule = angular.module('ngRouteForMultiView', ['ng', 'ngRoute']).controller('aaaCtrl', function($log) {});

  DEFAULT_VIEW_KEY = void 0;

  OTHERWISE_PATH = null;

  $Route4MultiViewProvider = (function() {
    var $http, $injector, $location, $q, $rootScope, $route, $routeParams, $sce, $templateCache, forceReload, inherit, interpolate, parseRoute, pathRegExp, routes, setInject, switchRouteMatcher, updateRoute;

    function $Route4MultiViewProvider() {}

    routes = {};

    $route = $rootScope = $location = $routeParams = $q = $injector = $http = $templateCache = $sce = forceReload = void 0;

    forceReload = false;

    setInject = function() {
      var injects;
      injects = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return $route = injects[0], $rootScope = injects[1], $location = injects[2], $routeParams = injects[3], $q = injects[4], $injector = injects[5], $http = injects[6], $templateCache = injects[7], $sce = injects[8], injects;
    };

    $Route4MultiViewProvider.prototype.when = function(path, route, views) {
      var redirectPath;
      routes[path] = angular.extend({
        reloadOnSearch: true
      }, route, path && pathRegExp(path, route), {
        "views": angular.extend({
          DEFAULT_VIEW_KEY: {
            controller: route.controller,
            controllerAs: route.controllerAs,
            template: route.template,
            templateUrl: route.templateUrl,
            resolve: route.resolve
          }
        }, views)
      });
      if (path) {
        redirectPath = path[path.length - 1] === '/' ? path.substr(0, path.length - 1) : "" + path + "/";
        routes[redirectPath] = angular.extend({
          redirectTo: path
        }, pathRegExp(redirectPath, route));
      }
      return this;
    };

    $Route4MultiViewProvider.prototype.otherwise = function(params) {
      return this.when(OTHERWISE_PATH, params);
    };

    $Route4MultiViewProvider.prototype.$get = [
      '$rootScope', '$location', '$routeParams', '$q', '$injector', '$http', '$templateCache', '$sce', function($rootScope, $location, $routeParams, $q, $injector, $http, $templateCache, $sce) {
        $route = {
          routes: routes,
          reload: function() {
            forceReload = true;
            return $rootScope.$evalAsync(updateRoute);
          }
        };
        setInject($route, $rootScope, $location, $routeParams, $q, $injector, $http, $templateCache, $sce);
        $rootScope.$on('$locationChangeSuccess', updateRoute);
        return $route;
      }
    ];

    pathRegExp = function(path, opts) {
      var insensitive, keys, ret;
      insensitive = opts.caseInsensitiveMatch;
      ret = {
        originalPath: path,
        regexp: path
      };
      keys = ret.keys = [];
      path = path.replace(/([().])/g, '\\$1').replace(/(\/)?:(\w+)([\?\*])?/g, function(_, slash, key, option) {
        var optional, star;
        optional = option === '?' ? option : null;
        star = option === '*' ? option : null;
        keys.push({
          name: key,
          optional: !!optional
        });
        slash = slash || '';
        return "" + (optional ? '' : slash) + "(?:" + (optional ? slash : '') + (star ? '(.+?)' : '([^/]+)') + (optional || '') + ")" + (optional || '');
      }).replace(/([\/$\*])/g, '\\$1');
      ret.regexp = new RegExp("^" + path + "$", insensitive ? 'i' : '');
      return ret;
    };

    inherit = function(parent, extra) {
      return angular.extend(new (angular.extend((function() {})({}, {
        prototype: parent
      })))(), extra);
    };

    switchRouteMatcher = function(_on, route) {
      var i, key, keys, m, params, v, val, _i, _len;
      keys = route.keys;
      params = {};
      if (!route.regexp) {
        return null;
      }
      m = route.regexp.exec(_on);
      if (!m) {
        return null;
      }
      m.shift();
      for (i = _i = 0, _len = m.length; _i < _len; i = ++_i) {
        v = m[i];
        key = keys[i];
        val = 'string' === typeof v ? decodeURIComponent(v) : v;
        if (key && val) {
          params[key.name] = val;
        }
      }
      return params;
    };

    updateRoute = function() {
      var last, next;
      next = parseRoute();
      last = $route.current;
      if (next && last && next.$$route === last.$$route && angular.equals(next.pathParams, last.pathParams) && !next.reloadOnSearch && !faceReload) {
        last.params = next.params;
        angular.copy(last.params, $routeParams);
        return $rootScope.$broadcast('$routeUpdate', last);
      } else if (next || last) {
        forceReload = false;
        $rootScope.$broadcast('$routeChangeStart', next, last);
        $route.current = next;
        if (next) {
          if (next.redirectTo) {
            if (angular.isString(next.redirectTo)) {
              $location.path(interpolate(next.redirectTo, next.params)).search(next.params).replace();
            } else {
              $location.url(next.redirectTo(next.pathParams, $location.path(), $location.search())).replace();
            }
          }
        }
        return $q.when(next).then(function() {
          var allLocals;
          if (next) {
            allLocals = {};
            angular.forEach(next.views, function(view, viewKey) {
              var locals, template, templateUrl;
              locals = angular.extend({}, view.resolve, {
                "$viewKey": viewKey
              });
              template = templateUrl = null;
              angular.forEach(locals, function(value, key) {
                return locals[key] = angular.isString(value) ? $injector.get(value) : $injector.invoke(value, null, null, key);
              });
              if (angular.isDefined(template = view.template)) {
                if (angular.isFunction(template)) {
                  template = template(next.params);
                }
              } else if (angular.isDefined(templateUrl = view.templateUrl)) {
                if (angular.isFunction(templateUrl)) {
                  templateUrl = templateUrl(next.params);
                }
                templateUrl = $sce.getTrustedResourceUrl(templateUrl);
                if (angular.isDefined(templateUrl)) {
                  view.loadedTemplateUrl = templateUrl;
                  template = $http.get(templateUrl, {
                    cache: $templateCache
                  }).then(function(response) {
                    return response.data;
                  });
                }
              }
              if (angular.isDefined(template)) {
                locals['$template'] = template;
              }
              return allLocals[viewKey] = $q.all(locals);
            });
            return $q.all(allLocals);
          }
        }).then(function(locals) {
          if (next === $route.current) {
            if (next) {
              next.locals = locals;
              angular.copy(next.params, $routeParams);
            }
            return $rootScope.$broadcast('$routeChangeSuccess', next, last);
          }
        }, function(error) {
          if (next === $route.current) {
            return $rootScope.$broadcast('$routeChangeError', next, last, error);
          }
        });
      }
    };

    parseRoute = function() {
      var match, params,
        _this = this;
      params = match = null;
      angular.forEach(routes, function(route, path) {
        if (!match && (params = switchRouteMatcher($location.path(), route))) {
          match = inherit(route, {
            params: angular.extend({}, $location.search(), params),
            pathParams: params
          });
          return match.$$route = route;
        }
      });
      return match || routes[OTHERWISE_PATH] && inherit(routes[OTHERWISE_PATH], {
        params: {},
        pathParams: {}
      });
    };

    interpolate = function(string, params) {
      var result;
      result = [];
      angular.forEach((string || '').split(':'), function(segment, i) {
        var key, segmentMatch;
        if (i === 0) {
          return result.push(segment);
        } else {
          segmentMatch = segment.match(/(\w+)(.*)/);
          key = segmentMatch[1];
          result.push(params[key]);
          result.push(segmentMatch[2] || '');
          return delete params[key];
        }
      });
      return result.join('');
    };

    return $Route4MultiViewProvider;

  })();

  ngRoute4MultiViewModule.provider('$routeForMultiView', $Route4MultiViewProvider);

  ngMultiViewFactory = (function() {
    var $anchorScroll, $animate, $route, setInject;

    ngMultiViewFactory.$inject = ['$route', '$anchorScroll', '$animate'];

    $route = $anchorScroll = $animate = null;

    setInject = function() {
      var injects;
      injects = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return $route = injects[0], $anchorScroll = injects[1], $animate = injects[2], injects;
    };

    function ngMultiViewFactory($route, $anchorScroll, $animate) {
      setInject($route, $anchorScroll, $animate);
      ({
        restrict: 'ECA',
        terminal: true,
        priority: 400,
        transclude: 'element',
        link: function(scope, $element, attr, ctrl, $transclude) {
          var autoScrollExp, cleanupLastView, currentElement, currentScope, onloadExp, previousElement, update;
          currentScope = currentElement = previousElement = void 0;
          autoScrollExp = attr.autoscroll;
          onloadExp = attr.onload || '';
          cleanupLastView = function() {
            if (previousElement) {
              previousElement.remove();
              previousElement = null;
            }
            if (currentScope) {
              currentScope.$destroy();
              currentScope = null;
            }
            if (currentElement) {
              $animate.leave(currentElement, function() {
                return previousElement = null;
              });
              previousElement = currentElement;
              return currentElement = null;
            }
          };
          update = function() {
            var clone, current, locals, newScope, template;
            locals = $route.current && $route.current.locals;
            template = locals && locals.$template;
            if (angular.isDefined(template)) {
              newScope = scope.$new();
              current = $route.current;
              clone = $transclude(newScope, function(clone) {
                $animate.enter(clone, null, currentElement || $element, function() {
                  if (angular.isDefined(autoScrollExp) && (!autoScrollExp || scope.$eval(autoScrollExp))) {
                    $anchorScroll();
                  }
                });
                return cleanupLastView();
              });
              currentElement = clone;
              currentScope = current.scope = newScope;
              currentScope.$emit('$viewContentLoaded');
              return currentScope.$eval(onloadExp);
            } else {
              return cleanupLastView();
            }
          };
          scope.$on('$routeChangeSuccess', update);
          return update();
        }
      });
    }

    return ngMultiViewFactory;

  })();

  ngMultiViewFillContentFactory = (function() {
    ngMultiViewFillContentFactory.$inject = ['$compile', '$controller', '$route'];

    function ngMultiViewFillContentFactory($compile, $controller, $route) {
      ({
        restrict: 'ECA',
        priority: -400,
        link: function(scope, $element, attr) {
          var controller, current, link, locals, view;
          current = $route.current;
          locals = current.locals[attr.ngMultiView] || current.locals[DEFAULT_VIEW_KEY];
          view = current.views[attr.ngMultiView] || current.views[DEFAULT_VIEW_KEY];
          $element.html(locals.$template);
          link = $compile($element.contents());
          if (view.controller) {
            locals.$scope = scope;
            controller = $controller(view.controller, locals);
            if (view.controllerAs) {
              scope[view.controllerAs] = controller;
            }
            $element.data('$ngControllerController', controller);
            $element.children().data('$ngControllerController', controller);
          }
          return link(scope);
        }
      });
    }

    return ngMultiViewFillContentFactory;

  })();

  ngRoute4MultiViewModule.directive('ngMultiView', ngMultiViewFactory);

  ngRoute4MultiViewModule.directive('ngMultiView', ngMultiViewFillContentFactory);

}).call(this);

/*
//@ sourceMappingURL=ng-route-for-multi-view.js.map
*/