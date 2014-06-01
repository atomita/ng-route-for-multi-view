"use strict"

module.exports = (grunt) ->
	require("load-grunt-tasks") grunt
	require("time-grunt") grunt
	
	grunt.initConfig
		
		project:
			name: require('./package.json').name
			version: require('./package.json').version
			src: "src"
			dist: "dist"
			temp: ".tmp"
			banner: """
				/** <%= project.name %> - v<%= project.version %> - <%= grunt.template.today("yyyy-mm-dd") %>
				 * @ngdoc module
				 * @name ngRouteForMultiView
				 * @description

				 */
				"""

		
		# Watches files for changes and runs tasks based on the changed files
		watch:
			bower:
				files: ["bower.json"]
				tasks: ["bowerInstall"]

			coffee:
				files: ["<%= project.src %>/{,*/}*.{coffee,litcoffee,coffee.md}"]
				tasks: ["newer:coffee:dist"]

			coffeeTest:
				files: ["test/spec/{,*/}*.{coffee,litcoffee,coffee.md}"]
				tasks: [
					"newer:coffee:test"
					"karma"
				]

			gruntfile:
				files: ["Gruntfile.coffee"]


		clean:
			dist:
				files: [
					dot: true
					src: [
						"<%= project.temp %>"
						"<%= project.dist %>/*"
						"!<%= project.dist %>/.git*"
					]
				]

			server: "<%= project.temp %>"

		
		# Compiles CoffeeScript to JavaScript
		coffee:
			options:
				sourceMap: true
				sourceRoot: ""

			dist:
				files: [
					expand: true
					cwd: "<%= project.src %>"
					src: "{,*/}*.coffee"
					dest: "<%= project.dist %>"
					ext: ".js"
				]

			test:
				files: [
					expand: true
					cwd: "test/spec"
					src: "{,*/}*.coffee"
					dest: ".tmp/spec"
					ext: ".js"
				]

		
		# ngmin tries to make the code safe for minification automatically by
		# using the Angular long form for dependency injection. It doesn't work on
		# things like resolve or inject so those have to be done manually.
		ngmin:
			dist:
				files: [
					expand: true
					cwd: "<%= project.dist %>"
					src: "*.js"
					dest: "<%= project.dist %>/min"
				]

		uglify:
			options:
				banner: "<%= project.banner %>"
				mangle:
					except: ["angular"]
			dist:
				files: [
					expand : true
					cwd: "<%= project.dist %>/min"
					src: "*.js"
					dest: "<%= project.dist %>/min"
				]

		
		# Run some tasks in parallel to speed up the build process
		concurrent:
			server: [
				"coffee:dist"
			]
			test: [
				"coffee"
			]
			dist: [
				"coffee"
			]

		
		# Test settings
		karma:
			unit:
				configFile: "karma.conf.js"
				singleRun: true

	grunt.registerTask "serve", (target) ->
		if target is "dist"
			return grunt.task.run([
				"build"
			])
		grunt.task.run [
			"clean:server"
			"concurrent:server"
			"watch"
		]
		return

	grunt.registerTask "server", (target) ->
		grunt.log.warn "The `server` task has been deprecated. Use `grunt serve` to start a server."
		grunt.task.run ["serve:" + target]
		return

	grunt.registerTask "test", [
		"clean:server"
		"concurrent:test"
		"karma"
	]
	grunt.registerTask "build", [
		"clean:dist"
		"concurrent:dist"
		"ngmin"
		"uglify"
	]
	grunt.registerTask "default", [
		"test"
		"build"
	]
	return
