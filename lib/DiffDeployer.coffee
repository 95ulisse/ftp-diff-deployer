JSFtp = require 'jsftp'
async = require 'async'
Path = require 'path'
_ = require 'lodash'
utils = require './utils'

normalizeFtpPath = (path) ->
	path.split(Path.sep).join '/'

module.exports = class DiffDeployer

	constructor: (@options = {}) ->

		# Checks for required options
		if not options.auth || typeof options.auth != 'object'
			throw new Error "'auth' parameter is required"
		if not options.host
			throw new Error "'host' parameter is required"
		if not options.diff
			throw new Error "'diff' parameter is required"
		if not options.src
			throw new Error "'src' parameter is required"
		if not options.dest
			throw new Error "'dest' parameter is required"

		# Defaults
		options.reporter ||= new(require './reporters/NullReporter')
		options.retry ||= 2

	deploy: (done) ->

		# Useful references
		auth = @options.auth
		reporter = @options.reporter
		src = @options.src
		dest = @options.dest
		retry = @options.retry

		# New JSFtp instance
		ftp = new JSFtp
			host: @options.host
			port: @options.port
			user: @options.auth.username
			pass: @options.auth.password

		async.waterfall [

			# Authentication
			(callback) ->
				ftp.auth auth.username, auth.password, (e) ->
					if e
						callback utils.wrapError 'Authentication failed', e
					else
						reporter.authenticated auth.username
						callback null

			# Computes diff
			(callback) =>
				reporter.diffStarted()
				@options.diff.compute (e, diff) ->
					if e
						callback utils.wrapError 'Diff computation failed', e
					else
						reporter.diffFinished diff
						callback null, diff

			# Creates needed folders on the server
			# from the new and modified files of the diff
			(diff, callback) ->

				# List of dirs to create
				dirs = []
				allFiles = diff.new.concat diff.modified
				for f in allFiles
					f = normalizeFtpPath Path.join dest, Path.dirname f
					f.split('/').reduce (a, b) ->
						dirs.push a + '/' + b
						return a + '/' + b
				dirs = _.unique _.sortBy(dirs, (x) -> x.split('/').length), true

				# Creates the directories
				async.eachSeries dirs, ((dir, cb) ->

					# Issues an LS command to check if the directory exists
					ftp.ls dir, (e, results) ->
						# If an error is returned, the directory does not exist
						if not e and results?.length? and results.length >= 0
							cb null # Directory already exists
						else

							#Creates the directory
							ftp.raw.mkd dir, (e) ->
								if e
									cb utils.wrapError 'Error while creating directory ' + dir, e
								else
									reporter.directoryCreated dir
									cb null # Directory successfully created

				), ((e) ->
					if e
						callback e
					else
						callback null, diff
				)

			# Uploads new and modified files
			(diff, callback) ->

				async.eachSeries diff.new.concat(diff.modified), ((file, cb) ->

					# Full source and destination path
					fullSrc = Path.join src, file
					fullDest = normalizeFtpPath Path.join dest, file

					# Uploads the file
					func = (retry) ->
						reporter.uploadStarted file
						ftp.put fullSrc, fullDest, (e) ->
							if e
								retry--
								if retry is 0
									cb utils.wrapError 'Error while uploading file ' + file, e
								else
									reporter.newAttempt retry
									func retry
							else
								reporter.uploadFinished()
								cb null
					func retry

				), ((e) ->
					if e
						callback e
					else
						callback null, diff
				)

			# Deletes files
			(diff, callback) ->

				async.eachSeries diff.removed, ((file, cb) ->

					# Full destination path
					fullDest = normalizeFtpPath Path.join dest, file

					# Removes the file
					func = (retry) ->
						ftp.raw.dele fullDest, (e) ->
							if e
								retry--
								if retry is 0
									cb utils.wrapError 'Error while deleting file ' + file, e
								else
									reporter.newAttempt retry
									func retry
							else
								reporter.fileRemoved file
								cb null
					func retry

				), ((e) ->
					if e
						callback e
					else
						callback null, diff
				)

		], (e) ->
			reporter.error e if e
			ftp.raw.quit () ->
				done e, null