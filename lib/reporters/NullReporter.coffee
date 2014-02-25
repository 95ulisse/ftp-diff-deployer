noop = () ->
	
module.exports = class NullReporter
	error: noop
	ok: noop

	authenticated: noop
	diffStarted: noop
	diffFinished: noop
	directoryCreated: noop
	uploadStarted: noop
	uploadProgress: noop
	uploadFinished: noop
	fileRemoved: noop
	newAttempt: noop