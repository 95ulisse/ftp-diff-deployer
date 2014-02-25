os = require 'os'
utils = require '../utils'
require 'colors'

formatError = (e, tab = '') ->
	return e if typeof e == 'string'
	str = tab + e.message
	str += "#{os.EOL}#{tab}Data:#{os.EOL + utils.inspect e.data}" if e.data
	str += "#{os.EOL}#{tab}Stack:#{os.EOL + e.stack}" if e.stack
	str += "#{os.EOL + os.EOL}#{tab}Inner error:#{os.EOL + formatError e.inner, tab + '\t'}" if e.inner
	return str

module.exports = class SimpleReporter

	write: (msg, stream = process.stdout) ->
		stream.write msg

	error: (e) ->
		@write os.EOL + os.EOL + formatError(e).red, process.stderr

	ok: (msg) ->
		@write ">> ".green + msg + os.EOL

	authenticated: (username) ->
		@ok "Authenticated as #{username.green}"

	diffStarted: () ->
		@ok "Diff started"

	diffFinished: (diff) ->
		@ok "Got diff: #{diff.new.length.toString().green} #{diff.modified.length.toString().cyan} #{diff.removed.length.toString().red}"

	directoryCreated: (path) ->
		@ok "Remote directory created: #{path.yellow}"

	uploadStarted: (path) ->
		@write ">> ".green + "Uploading #{path.yellow}"

	uploadProgress: (percentage) ->

	uploadFinished: () ->
		@write " - " + "Done".green + os.EOL

	fileRemoved: (path) ->
		@ok "Remote file deleted: #{path.yellow}"

	newAttempt: (attemptsLeft) ->
		@write ">> Retrying. Attempts left: #{attemptsLeft}".cyan + os.EOL