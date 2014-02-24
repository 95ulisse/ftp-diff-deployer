module.exports = (grunt) ->

	grunt.initConfig

		# Test
		mochaTest:
			test:
				options:
					reporter: 'spec'
					require: [
						'coffee-script/register'
						'should'
					]
				src: [ 'test/**/*.coffee' ]


	# Loads tasks
	grunt.loadNpmTasks 'grunt-mocha-test'

	# Registers tasks
	grunt.registerTask 'test', [ 'mochaTest' ]