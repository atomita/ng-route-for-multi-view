###
# @ngdoc module
# @name ngRouteForMultiView
# @description
# 
###
ngRoute4MultiViewModule = angular.module('ngRouteForMultiView', ['ng'])



class $Route4MultiViewProvider

	routes = {}

	when: (path, route, views)->
		routes[path] = angular.extend(
			{reloadOnSearch: true}
			route
			path && pathRegExp(path, route)
			{"views": views}
		)

		if path
			redirectPath = if path[path.length-1] == '/' then path.substr(0, path.length-1) else "#{path}/";

			routes[redirectPath] = angular.extend(
				{redirectTo: path}
				pathRegExp(redirectPath, route)
			)

		@


	otherwise: (params)->
		@when(null, params)


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

			route = new Route(routes, $route, $rootScope, $location, $routeParams, $q, $injector, $http, $templateCache, $sce)

			$route.reload = ->
					route.forceReload = true
					$rootScope.$evalAsync(route.updateRoute)
       
			$rootScope.$on('$locationChangeSuccess', route.updateRoute);

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


ngRoute4MultiViewModule.provider('$routeForMultiView', $Route4MultiViewProvider)



class Route
	constructor: (@routes, @$route, @$rootScope, @$location, @$routeParams, @$q, @$injector, @$http, @$templateCache, @$sce)->
		@forceReload = false


	switchRouteMatcher: (on, route)->
		keys = route.keys
		params = {}

		if not route.regexp
			return null

		m = route.regexp.exec(on)
		if not m
			return null

		m.shift()
		for v, i in m
			key = keys[i]
			val = if 'string' == typeof v then decodeURIComponent(v) else v

			if key && val
				params[key.name] = val
			
		params


	updateRoute: =>
		next = @parseRoute()
		last = @$route.current

		if next and last and next.$$route == last.$$route and
		angular.equals(next.pathParams, last.pathParams) and
		not next.reloadOnSearch and not @faceReload

			last.params = next.params
			angular.copy(last.params, @$routeParams)
			@$rootScope.$broadcast('$routeUpdate', last)

		else if next || last
			@forceReload = false
			@$rootScope.$broadcast('$routeChangeStart', next, last)
			@$route.current = next

			if next
				if next.redirectTo
					if angular.isString(next.redirectTo)
						@$location.path(@interpolate(next.redirectTo, next.params)).search(next.params).replace()
					else
						@$location.url(next.redirectTo(next.pathParams, @$location.path(), @$location.search())).replace()

			$q.when(next).then(=>
				if next
					locals = angular.extend({}, next.resolve)
					template = templateUrl = null

					angular.forEach(locals, (value, key)=>
						locals[key] = if angular.isString(value) then
							@$injector.get(value) else @$injector.invoke(value, null, null, key)
					)

					if angular.isDefined(template = next.template)
						if angular.isFunction(template)
							template = template(next.params)
						
					else if angular.isDefined(templateUrl = next.templateUrl)
						if angular.isFunction(templateUrl)
							templateUrl = templateUrl(next.params)
						
						templateUrl = @$sce.getTrustedResourceUrl(templateUrl)
						if angular.isDefined(templateUrl)
							next.loadedTemplateUrl = templateUrl
							template = @$http.get(templateUrl, {cache: $templateCache}).
							then((response)-> response.data)
					
					if angular.isDefined(template)
						locals['$template'] = template

					return @$q.all(locals)
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


	parseRoute: ->
		# Match a route
		params = match = null
		angular.forEach(@routes, (route, path)=>
			if not match && (params = @switchRouteMatcher(@$location.path(), route))
				match = inherit(route, 
					params: angular.extend({}, @$location.search(), params)
					pathParams: params
				)
				match.$$route = route
		)
		# No route matched; fallback to "otherwise" route
		match || @routes[null] && inherit(@routes[null], {params: {}, pathParams:{}})


	interpolate: (string, params)->
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




inherit = (parent, extra)->
	angular.extend(new (angular.extend((->) {}, {prototype:parent}))(), extra)
