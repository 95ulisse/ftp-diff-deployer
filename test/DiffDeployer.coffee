utils = require('./testUtils')

newDiffDeployer = (options) ->
	DiffDeployer = utils.require 'DiffDeployer'
	return new DiffDeployer options || {}

describe 'DiffDeployer test', () ->

	it 'Throws for missing options', () ->
		(() ->
			newDiffDeployer()
		).should.throw()

		(() ->
			newDiffDeployer auth: {}
		).should.throw()

		(() ->
			newDiffDeployer auth: { username: '', password: '' }
		).should.throw()

		(() ->
			newDiffDeployer auth: { username: '', password: '' }, diff: {}
		).should.throw()

		(() ->
			newDiffDeployer auth: { username: '', password: '' }, diff: {}, host: 'x'
		).should.throw()

		(() ->
			newDiffDeployer auth: { username: '', password: '' }, diff: {}, host: 'x', src: 'x'
		).should.throw()

		(() ->
			newDiffDeployer auth: { username: '', password: '' }, diff: {}, host: 'x', src: 'x', dest: 'x'
		).should.not.throw()