###
# @ngdoc module
# @name ngRouteForMultiView
# @description
# 
###
ngRoute4MultiViewModule = angular.module('ngRouteForMultiView', ['ng', 'ngRoute'])


DEFAULT_VIEW_KEY = undefined
OTHERWISE_PATH = null

class $Route4MultiViewProvider

	routes = {}
	$route = $rootScope = $location = $routeParams = $q = $injector = $http = $templateCache = $sce = forceReload = undefined
	forceReload = false
	setInject = (injects...)->
		[$route, $rootScope, $location, $routeParams, $q, $injector, $http, $templateCache, $sce] = injects

	when: (path, route, views)->
		routes[path] = angular.extend(
			{reloadOnSearch: true}
			route
			path && pathRegExp(path, route)
			{
				"views": angular.extend({
					DEFAULT_VIEW_KEY:
						controller: route.controller
						controllerAs: route.controllerAs
						template: route.template
						templateUrl: route.templateUrl
						resolve: route.resolve
				}, views)
			}
		)

		if path
			redirectPath = if path[path.length-1] == '/' then path.substr(0, path.length-1) else "#{path}/";

			routes[redirectPath] = angular.extend(
				{redirectTo: path}
				pathRegExp(redirectPath, route)
			)

		@


	otherwise: (params)->
		@when(OTHERWISE_PATH, params)


	$get: [
		'$rootScope'
		'$location'
		'$routeParams'
		'$q'
		'$injector'
		'$http'
		'$templateCache'
		'$sce'
		($rootScope, $location, $routeParams, $q, $injector, $http, $templateCache, $sce)->
			$route =
				routes: routes
				reload: ->
					forceReload = true
					$rootScope.$evalAsync(updateRoute)

			setInject($route, $rootScope, $location, $routeParams, $q, $injector, $http, $templateCache, $sce)

			$rootScope.$on('$locationChangeSuccess', updateRoute);

			$route
	]


	pathRegExp = (path, opts)->
		insensitive = opts.caseInsensitiveMatch
		ret =
			originalPath: path
			regexp: path
		keys = ret.keys = []

		path = path.replace(/([().])/g, '\\$1').replace(/(\/)?:(\w+)([\?\*])?/g, (_, slash, key, option)->
			optional = if option == '?' then option else null
			star = if option == '*' then option else null
			keys.push({ name: key, optional: !!optional })
			slash = slash || ''
			
			"#{if optional then '' else slash}(?:#{if optional then slash else ''}#{if star then '(.+?)' else '([^/]+)'}#{optional || ''})#{optional || ''}"
		).replace(/([\/$\*])/g, '\\$1')

		ret.regexp = new RegExp("^#{path}$", if insensitive then 'i' else '');
		ret


	inherit = (parent, extra)->
		angular.extend(new (angular.extend((->) {}, {prototype:parent}))(), extra)


	switchRouteMatcher = (_on, route)->
		keys = route.keys
		params = {}

		if not route.regexp
			return null

		m = route.regexp.exec(_on)
		if not m
			return null

		m.shift()
		for v, i in m
			key = keys[i]
			val = if 'string' == typeof v then decodeURIComponent(v) else v

			if key && val
				params[key.name] = val
			
		params


	updateRoute = ->
		next = parseRoute()
		last = $route.current

		if next and last and next.$$route == last.$$route and
		angular.equals(next.pathParams, last.pathParams) and
		not next.reloadOnSearch and not faceReload

			last.params = next.params
			angular.copy(last.params, $routeParams)
			$rootScope.$broadcast('$routeUpdate', last)

		else if next || last
			forceReload = false
			$rootScope.$broadcast('$routeChangeStart', next, last)
			$route.current = next

			if next
				if next.redirectTo
					if angular.isString(next.redirectTo)
						$location.path(interpolate(next.redirectTo, next.params)).search(next.params).replace()
					else
						$location.url(next.redirectTo(next.pathParams, $location.path(), $location.search())).replace()

			$q.when(next).then(->
				if next
					allLocals = {}
					angular.forEach(next.views, (view, viewKey)->
						locals = angular.extend({}, view.resolve, {"$viewKey": viewKey})
						template = templateUrl = null

						angular.forEach(locals, (value, key)->
							locals[key] = if angular.isString(value) then $injector.get(value) else $injector.invoke(value, null, null, key)
						)
	
						if angular.isDefined(template = view.template)
							if angular.isFunction(template)
								template = template(next.params)
							
						else if angular.isDefined(templateUrl = view.templateUrl)
							if angular.isFunction(templateUrl)
								templateUrl = templateUrl(next.params)
							
							templateUrl = $sce.getTrustedResourceUrl(templateUrl)
							if angular.isDefined(templateUrl)
								view.loadedTemplateUrl = templateUrl
								template = $http.get(templateUrl, {cache: $templateCache}).
								then((response)-> response.data)
						
						if angular.isDefined(template)
							locals['$template'] = template

						allLocals[viewKey] = $q.all(locals)
					)
					
					return $q.all(allLocals)
				return
			)
			# after route change
			.then((locals)->
				if next == $route.current
					if next
						next.locals = locals
						angular.copy(next.params, $routeParams);

					$rootScope.$broadcast('$routeChangeSuccess', next, last)
			, (error)->
				if next == $route.current
					$rootScope.$broadcast('$routeChangeError', next, last, error)
			)


	parseRoute = ->
		# Match a route
		params = match = null
		angular.forEach(routes, (route, path)=>
			if not match && (params = switchRouteMatcher($location.path(), route))
				match = inherit(route, 
					params: angular.extend({}, $location.search(), params)
					pathParams: params
				)
				match.$$route = route
		)
		# No route matched; fallback to "otherwise" route
		match || routes[OTHERWISE_PATH] && inherit(routes[OTHERWISE_PATH], {params: {}, pathParams:{}})


	interpolate = (string, params)->
		result = []
		angular.forEach((string || '').split(':'), (segment, i)->
			if i == 0
				result.push(segment)
			else
				segmentMatch = segment.match(/(\w+)(.*)/)
				key = segmentMatch[1]
				result.push(params[key])
				result.push(segmentMatch[2] || '')
				delete params[key]
		)
		result.join('')




ngRoute4MultiViewModule.provider('$routeForMultiView', $Route4MultiViewProvider)


class ngMultiViewFactory
	@$inject = ['$route', '$anchorScroll', '$animate']
	$route = $anchorScroll = $animate = null
	setInject = (injects...)->
		[$route, $anchorScroll, $animate] = injects
	
	constructor: ($route, $anchorScroll, $animate)->
		setInject($route, $anchorScroll, $animate)
		{
			restrict: 'ECA'
			terminal: true
			priority: 400
			transclude: 'element'
			link: (scope, $element, attr, ctrl, $transclude)->
				cleanupLastView = ->
					if previousElement
						previousElement.remove()
						previousElement = null
					
					if currentScope
						currentScope.$destroy()
						currentScope = null
					
					if currentElement
						$animate.leave(currentElement, ->
							previousElement = null
						)
						previousElement = currentElement
						currentElement = null

		
				update = ->
					locals = $route.current && $route.current.locals
					template = locals && locals.$template
		
					if angular.isDefined(template)
						newScope = scope.$new()
						current = $route.current
		
						clone = $transclude(newScope, (clone)->
							$animate.enter(clone, null, currentElement || $element, ()->
								# onNgViewEnter
								if angular.isDefined(autoScrollExp) and
								(!autoScrollExp || scope.$eval(autoScrollExp))
									$anchorScroll()
								return
							)
							cleanupLastView()
						)
		
						currentElement = clone
						currentScope = current.scope = newScope
						currentScope.$emit('$viewContentLoaded')
						currentScope.$eval(onloadExp)
					else
						cleanupLastView()

				currentScope = currentElement =  previousElement = undefined
				autoScrollExp = attr.autoscroll
				onloadExp = attr.onload || ''
			
				scope.$on('$routeChangeSuccess', update)
				update()
		}




class ngMultiViewFillContentFactory
	@$inject = ['$compile', '$controller', '$route']
	
	constructor: ($compile, $controller, $route)->
		{
			restrict: 'ECA',
			priority: -400,
			link: (scope, $element, attr)->
				current = $route.current
				locals = current.locals[attr.ngMultiView] || current.locals[DEFAULT_VIEW_KEY]
				view = current.views[attr.ngMultiView] || current.views[DEFAULT_VIEW_KEY]
	
				$element.html(locals.$template)

				link = $compile($element.contents())

				if view.controller
					locals.$scope = scope
					controller = $controller(view.controller, locals)
					if view.controllerAs
						scope[view.controllerAs] = controller
					
					$element.data('$ngControllerController', controller)
					$element.children().data('$ngControllerController', controller)
				
				link(scope)
		}


ngRoute4MultiViewModule.directive('ngMultiView', ngMultiViewFactory)
ngRoute4MultiViewModule.directive('ngMultiView', ngMultiViewFillContentFactory)
